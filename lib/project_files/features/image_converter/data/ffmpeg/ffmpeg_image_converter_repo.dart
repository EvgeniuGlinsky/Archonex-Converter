import 'dart:async';
import 'dart:io';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter_new/log.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:flutter/services.dart';

import 'package:archonex/project_files/features/converter_shared/data/ffmpeg/ffmpeg_error_classifier.dart';
import 'package:archonex/project_files/features/converter_shared/domain/models/conversion_failure.dart';
import 'package:archonex/project_files/features/converter_shared/domain/models/converted_file.dart';
import 'package:archonex/project_files/features/converter_shared/domain/models/source_file.dart';
import 'package:archonex/project_files/features/image_converter/data/ffmpeg/ffmpeg_image_command_builder.dart';
import 'package:archonex/project_files/features/image_converter/domain/image_converter_repo.dart';
import 'package:archonex/project_files/features/image_converter/domain/models/image_conversion_job.dart';
import 'package:archonex/project_files/features/image_converter/domain/models/image_conversion_settings.dart';
import 'package:archonex/project_files/features/image_converter/domain/models/image_conversion_update.dart';
import 'package:archonex/project_files/features/image_converter/domain/models/image_format.dart';

/// Real conversion, backed by the FFmpeg binaries bundled with
/// `ffmpeg_kit_flutter_new`.
///
/// The plugin ships native libraries for Android, iOS, macOS and Windows only.
/// Linux gets no engine, which [isSupported] reports up front; should a call
/// slip through anyway, the resulting `MissingPluginException` is mapped to
/// [ConversionUnsupportedFailure] rather than a generic error.
class FfmpegImageConverterRepo implements ImageConverterRepo {
  const FfmpegImageConverterRepo();

  static const String _tempDirectoryPrefix = 'archonex_images_';

  @override
  bool get isSupported => !Platform.isLinux;

  @override
  ImageConversionJob convert({
    required List<SourceFile> sources,
    required ImageFormat target,
    required ImageConversionSettings settings,
  }) {
    return _FfmpegImageConversionJob(
      sources: sources,
      target: target,
      settings: settings,
      tempDirectoryPrefix: _tempDirectoryPrefix,
    );
  }

  @override
  Future<void> discard(List<ConvertedFile> files) async {
    // A batch writes every output into one temporary directory, so the set of
    // parents is almost always a single entry — deleting it takes the whole
    // batch with it.
    final Set<String> directories = files
        .map((file) => File(file.path).parent.path)
        .toSet();

    for (final String path in directories) {
      await _deleteDirectory(Directory(path));
    }
  }

  static Future<void> _deleteDirectory(Directory directory) async {
    try {
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    } on FileSystemException {
      // A leftover temp directory is not worth surfacing to the user; the OS
      // reclaims it eventually.
    }
  }
}

/// One batch, exposed as a stream of per-photo results that can be stopped.
///
/// Photos are converted strictly one at a time. Running them in parallel would
/// multiply peak memory by the number of workers for a job that is already
/// fast per item, and it would make cancellation a question of how many
/// sessions are in flight rather than of one.
class _FfmpegImageConversionJob implements ImageConversionJob {
  _FfmpegImageConversionJob({
    required List<SourceFile> sources,
    required ImageFormat target,
    required ImageConversionSettings settings,
    required String tempDirectoryPrefix,
  })  : _sources = sources,
        _target = target,
        _settings = settings,
        _tempDirectoryPrefix = tempDirectoryPrefix {
    _controller = StreamController<ImageConversionUpdate>(onListen: _start);
  }

  final List<SourceFile> _sources;
  final ImageFormat _target;
  final ImageConversionSettings _settings;
  final String _tempDirectoryPrefix;

  late final StreamController<ImageConversionUpdate> _controller;

  Directory? _tempDirectory;
  int? _sessionId;
  bool _isCancelling = false;

  @override
  Stream<ImageConversionUpdate> get updates => _controller.stream;

  @override
  Future<void> cancel() async {
    _isCancelling = true;

    final int? sessionId = _sessionId;

    if (sessionId == null) {
      // Between items, or before the first one started: nothing native to
      // stop, so the queue is ended here.
      await _finishWith(const ConversionCancelledFailure());

      return;
    }

    await FFmpegKit.cancel(sessionId);
  }

  Future<void> _start() async {
    try {
      _tempDirectory =
          await Directory.systemTemp.createTemp(_tempDirectoryPrefix);
    } on FileSystemException {
      await _finishWith(const InsufficientStorageFailure());

      return;
    }

    for (int index = 0; index < _sources.length; index++) {
      if (_isCancelling || _controller.isClosed) {
        break;
      }

      _controller.add(ImageItemStarted(index));

      final ImageConversionUpdate update =
          await _convertOne(index, _sources[index]);

      if (_isCancelling || _controller.isClosed) {
        break;
      }

      _controller.add(update);
    }

    if (_isCancelling) {
      await _finishWith(const ConversionCancelledFailure());

      return;
    }

    if (!_controller.isClosed) {
      await _controller.close();
    }
  }

  Future<ImageConversionUpdate> _convertOne(
    int index,
    SourceFile source,
  ) async {
    final String? inputPath = source.path;
    if (inputPath == null) {
      // No local path means no engine can read it — only reachable on web.
      return ImageItemFailed(index, const ConversionUnsupportedFailure());
    }

    final ImageFormat? sourceFormat =
        ImageFormat.fromExtension(source.extension);
    if (sourceFormat == null) {
      return ImageItemFailed(
        index,
        UnsupportedFormatFailure(actualExtension: source.extension),
      );
    }

    final String outputName = '${source.baseName}.${_target.extension}';

    // Prefixed with the position so two sources that differ only by extension
    // cannot overwrite each other inside the shared temp directory. The name
    // offered at save time stays the clean one.
    final String outputPath = '${_tempDirectory!.path}'
        '${Platform.pathSeparator}${index}_$outputName';

    final List<String> arguments;
    try {
      arguments = FfmpegImageCommandBuilder.build(
        inputPath: inputPath,
        outputPath: outputPath,
        source: sourceFormat,
        target: _target,
        settings: _settings,
      );
    } on ArgumentError {
      return ImageItemFailed(index, const ConversionEngineFailure());
    }

    // A stream FFmpeg cannot find in a picture means the file holds no picture,
    // which is a broken source rather than a missing audio track.
    final FfmpegErrorClassifier classifier = FfmpegErrorClassifier(
      missingStreamFailure: const CorruptSourceFailure(),
    );
    final Completer<ImageConversionUpdate> completed =
        Completer<ImageConversionUpdate>();

    try {
      final FFmpegSession session = await FFmpegKit.executeWithArgumentsAsync(
        arguments,
        (session) async => completed.complete(
          await _outcome(
            session: session,
            index: index,
            outputPath: outputPath,
            outputName: outputName,
            classifier: classifier,
          ),
        ),
        (Log log) => classifier.add(log.getMessage()),
      );

      _sessionId = session.getSessionId();

      // A cancel that landed while the session was starting up.
      if (_isCancelling) {
        await FFmpegKit.cancel(_sessionId);
      }
    } on MissingPluginException {
      return ImageItemFailed(index, const ConversionUnsupportedFailure());
    } on Exception {
      return ImageItemFailed(index, const ConversionEngineFailure());
    }

    final ImageConversionUpdate update = await completed.future;
    _sessionId = null;

    return update;
  }

  Future<ImageConversionUpdate> _outcome({
    required FFmpegSession session,
    required int index,
    required String outputPath,
    required String outputName,
    required FfmpegErrorClassifier classifier,
  }) async {
    final ReturnCode? returnCode = await session.getReturnCode();

    if (ReturnCode.isCancel(returnCode)) {
      _isCancelling = true;

      return ImageItemFailed(index, const ConversionCancelledFailure());
    }

    if (!ReturnCode.isSuccess(returnCode)) {
      return ImageItemFailed(
        index,
        classifier.classify() ?? const ConversionEngineFailure(),
      );
    }

    final File output = File(outputPath);
    if (!await output.exists()) {
      return ImageItemFailed(index, const ConversionEngineFailure());
    }

    return ImageItemConverted(
      index,
      ConvertedFile(
        name: outputName,
        path: outputPath,
        sizeInBytes: await output.length(),
      ),
    );
  }

  /// Ends the queue with [failure] and takes the temp directory with it —
  /// nothing downstream can reach a half finished batch.
  Future<void> _finishWith(ConversionFailure failure) async {
    await _deleteTempDirectory();

    if (_controller.isClosed) {
      return;
    }

    _controller.addError(failure);
    await _controller.close();
  }

  Future<void> _deleteTempDirectory() async {
    final Directory? directory = _tempDirectory;
    _tempDirectory = null;

    if (directory == null) {
      return;
    }

    try {
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    } on FileSystemException {
      // Best effort — see FfmpegImageConverterRepo.discard.
    }
  }
}
