import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;

import 'package:archonex_converter/project_files/features/converter_shared/domain/models/conversion_failure.dart';
import 'package:archonex_converter/project_files/features/converter_shared/domain/models/converted_file.dart';
import 'package:archonex_converter/project_files/features/converter_shared/domain/models/source_file.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/data/engine/pdf_document_writer.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/data/engine/pdf_page_rasterizer.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/data/engine/pdf_write_request.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/domain/models/pdf_conversion_job.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/domain/models/pdf_conversion_settings.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/domain/models/pdf_conversion_update.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/domain/models/pdf_format.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/domain/models/pdf_target.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/domain/pdf_converter_repo.dart';

/// The PDF engine, built on `pdf` for writing and `printing` for reading.
///
/// No FFmpeg anywhere: neither direction is a media problem. That also means it
/// works on every platform with a file system, Linux included, where the other
/// two converters have no engine at all.
class DartPdfConverterRepo implements PdfConverterRepo {
  const DartPdfConverterRepo();

  /// Embedded into every PDF the writer produces — see the note in
  /// `pubspec.yaml` for why the built in fonts are not enough.
  static const String fontAsset = 'assets/fonts/NotoSans-Regular.ttf';

  static const String temporaryDirectoryPrefix = 'archonex_pdf_';

  @override
  bool get isSupported => true;

  @override
  PdfConversionJob convert({
    required List<SourceFile> sources,
    required PdfTarget target,
    required PdfConversionSettings settings,
  }) =>
      _DartPdfConversionJob(
        sources: sources,
        target: target,
        settings: settings,
      );

  /// Deletes the directories the results sit in.
  ///
  /// Directories rather than files: one run writes everything into a single
  /// temporary directory, so removing it takes the whole run's leftovers with
  /// it, including anything a cancellation left half written.
  @override
  Future<void> discard(List<ConvertedFile> files) async {
    final Set<String> directories = files
        .map((file) => File(file.path).parent.path)
        .where((path) => path.contains(temporaryDirectoryPrefix))
        .toSet();

    for (final String path in directories) {
      try {
        await Directory(path).delete(recursive: true);
      } on FileSystemException {
        // Already gone, or still held by the platform. Nothing to recover.
      }
    }
  }
}

/// One run, in whichever of the two directions [target] implies.
class _DartPdfConversionJob implements PdfConversionJob {
  _DartPdfConversionJob({
    required List<SourceFile> sources,
    required PdfTarget target,
    required PdfConversionSettings settings,
  })  : _sources = sources,
        _target = target,
        _settings = settings {
    _controller = StreamController<PdfConversionUpdate>(onListen: _start);
  }

  final List<SourceFile> _sources;
  final PdfTarget _target;
  final PdfConversionSettings _settings;

  late final StreamController<PdfConversionUpdate> _controller;

  Directory? _directory;
  Isolate? _isolate;
  StreamSubscription<RasterizedPage>? _rasterSubscription;
  bool _isCancelled = false;

  @override
  Stream<PdfConversionUpdate> get updates => _controller.stream;

  @override
  Future<void> cancel() async {
    if (_isCancelled) {
      return;
    }
    _isCancelled = true;

    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    await _rasterSubscription?.cancel();
    _rasterSubscription = null;

    await _finishWith(const ConversionCancelledFailure());
  }

  Future<void> _start() async {
    try {
      _directory = await Directory.systemTemp.createTemp(
        DartPdfConverterRepo.temporaryDirectoryPrefix,
      );

      if (_target.mergesBatch) {
        await _writeMergedPdf();
      } else {
        await _rasterizeSources();
      }

      if (!_isCancelled) {
        await _controller.close();
      }
    } on ConversionFailure catch (failure) {
      await _finishWith(failure);
    } catch (_) {
      await _finishWith(const ConversionEngineFailure());
    }
  }

  /// Pictures or text going in: one document out, assembled off the UI isolate.
  Future<void> _writeMergedPdf() async {
    final PdfSourceKind? kind = PdfFormat.sharedKind(
      _sources.map(_formatOf).whereType<PdfFormat>(),
    );

    if (kind == null) {
      throw const MixedSourceKindsFailure();
    }

    final ByteData font = await rootBundle.load(DartPdfConverterRepo.fontAsset);
    final String name = '${_mergedBaseName()}.${_target.extension}';
    final String outputPath = _pathFor(name);

    final ReceivePort port = ReceivePort();
    final Completer<PdfWriteMessage> outcome = Completer<PdfWriteMessage>();

    port.listen((message) {
      if (message is PdfWriteProgress) {
        _emit(PdfProgressed(done: message.done, total: message.total));
      } else if (message is PdfWriteMessage && !outcome.isCompleted) {
        outcome.complete(message);
      }
    });

    _isolate = await Isolate.spawn(
      PdfDocumentWriter.run,
      PdfWriteRequest(
        replyPort: port.sendPort,
        sourcePaths: _sourcePaths(),
        outputPath: outputPath,
        kind: kind,
        settings: _settings,
        fontBytes: font.buffer.asUint8List(),
      ),
    );

    final PdfWriteMessage message = await outcome.future;
    port.close();
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;

    if (_isCancelled) {
      return;
    }

    switch (message) {
      case PdfWriteDone(:final int sizeInBytes):
        _emit(
          PdfFileProduced(
            ConvertedFile(
              name: name,
              path: outputPath,
              sizeInBytes: sizeInBytes,
            ),
          ),
        );
      case PdfWriteFailed(:final PdfWriteError error, :final String detail):
        throw _failureFor(error, detail);
      case PdfWriteProgress():
        throw const ConversionEngineFailure();
    }
  }

  /// A PDF going in: one picture per page out, written as each page lands.
  Future<void> _rasterizeSources() async {
    const PdfPageRasterizer rasterizer = PdfPageRasterizer();

    final List<Uint8List> documents = <Uint8List>[
      for (final SourceFile source in _sources)
        await File(source.path!).readAsBytes(),
    ];

    int total = 0;
    for (final Uint8List document in documents) {
      total += await rasterizer.countPages(document);
      if (_isCancelled) {
        return;
      }
    }

    if (total == 0) {
      throw const CorruptSourceFailure();
    }

    int done = 0;
    _emit(PdfProgressed(done: 0, total: total));

    for (int index = 0; index < documents.length; index++) {
      if (_isCancelled) {
        return;
      }

      final Stream<RasterizedPage> pages = rasterizer.rasterize(
        documentBytes: documents[index],
        directory: _directory!,
        baseName: _uniqueBaseName(index),
        target: _target,
        dpi: _settings.rasterDpi,
        quality: _settings.quality,
      );

      await for (final RasterizedPage page in pages) {
        if (_isCancelled) {
          return;
        }

        done++;
        _emit(
          PdfFileProduced(
            ConvertedFile(
              name: page.name,
              path: page.path,
              sizeInBytes: page.sizeInBytes,
            ),
          ),
        );
        _emit(PdfProgressed(done: done, total: total));
      }
    }
  }

  PdfFormat? _formatOf(SourceFile file) =>
      PdfFormat.fromExtension(file.extension);

  List<String> _sourcePaths() => <String>[
        for (final SourceFile source in _sources) source.path!,
      ];

  /// A merged document is named after its first source, which is the one the
  /// user sees at the top of the list.
  String _mergedBaseName() =>
      _sources.isEmpty ? 'document' : _sources.first.baseName;

  /// Pages from different sources share one directory, so the source index goes
  /// into the name — two PDFs both holding a `page` would otherwise collide.
  String _uniqueBaseName(int index) => _sources.length == 1
      ? _sources[index].baseName
      : '${index}_${_sources[index].baseName}';

  String _pathFor(String name) =>
      '${_directory!.path}${Platform.pathSeparator}$name';

  ConversionFailure _failureFor(PdfWriteError error, String detail) =>
      switch (error) {
        PdfWriteError.unsupportedCharacters =>
          UnsupportedCharactersFailure(sample: detail),
        PdfWriteError.unreadableSource => const FileReadFailure(),
        PdfWriteError.engine => const ConversionEngineFailure(),
      };

  void _emit(PdfConversionUpdate update) {
    if (!_controller.isClosed) {
      _controller.add(update);
    }
  }

  /// Ends the run, taking the whole temporary directory with it: a stopped run
  /// must not leave half of its output behind.
  Future<void> _finishWith(ConversionFailure failure) async {
    await _deleteDirectory();

    if (!_controller.isClosed) {
      _controller.addError(failure);
      await _controller.close();
    }
  }

  Future<void> _deleteDirectory() async {
    final Directory? directory = _directory;
    _directory = null;

    if (directory == null) {
      return;
    }

    try {
      await directory.delete(recursive: true);
    } on FileSystemException {
      // Nothing to recover: the run is ending either way.
    }
  }
}
