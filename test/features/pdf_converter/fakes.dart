import 'dart:async';

import 'package:archonex_converter/project_files/features/converter_shared/domain/models/conversion_failure.dart';
import 'package:archonex_converter/project_files/features/converter_shared/domain/models/converted_file.dart';
import 'package:archonex_converter/project_files/features/converter_shared/domain/models/save_result.dart';
import 'package:archonex_converter/project_files/features/converter_shared/domain/models/source_file.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/domain/models/pdf_conversion_job.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/domain/models/pdf_conversion_settings.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/domain/models/pdf_conversion_update.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/domain/models/pdf_target.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/domain/pdf_converter_repo.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/domain/pdf_file_repo.dart';

/// File access driven entirely by the test.
class FakePdfFileRepo implements PdfFileRepo {
  List<SourceFile> pickResult = <SourceFile>[];
  Object? pickError;
  List<int> readResult = <int>[];
  Object? readError;
  String? saveLocation;
  Object? saveError;
  SaveResult saveAllResult = const SaveResult(
    outcome: SaveOutcome.savedToLocation,
    location: '/downloads',
  );
  Object? saveAllError;

  @override
  bool reportsSaveLocation = true;

  int pickCallCount = 0;
  int saveCallCount = 0;
  int saveAllCallCount = 0;
  List<ConvertedFile>? lastSavedAll;

  @override
  Future<List<SourceFile>> pickSources() async {
    pickCallCount++;

    if (pickError != null) {
      throw pickError!;
    }

    return pickResult;
  }

  @override
  Future<List<int>> readSource(SourceFile file) async {
    if (readError != null) {
      throw readError!;
    }

    return readResult;
  }

  @override
  Future<String?> saveConverted(ConvertedFile file) async {
    saveCallCount++;

    if (saveError != null) {
      throw saveError!;
    }

    return saveLocation;
  }

  @override
  Future<SaveResult> saveAllConverted(List<ConvertedFile> files) async {
    saveAllCallCount++;
    lastSavedAll = files;

    if (saveAllError != null) {
      throw saveAllError!;
    }

    return saveAllResult;
  }
}

/// Engine driven entirely by the test.
class FakePdfConverterRepo implements PdfConverterRepo {
  @override
  bool isSupported = true;

  int convertCallCount = 0;
  List<SourceFile>? lastSources;
  PdfTarget? lastTarget;
  PdfConversionSettings? lastSettings;
  ControllablePdfConversionJob? lastJob;

  final List<ConvertedFile> discarded = <ConvertedFile>[];

  @override
  PdfConversionJob convert({
    required List<SourceFile> sources,
    required PdfTarget target,
    required PdfConversionSettings settings,
  }) {
    convertCallCount++;
    lastSources = sources;
    lastTarget = target;
    lastSettings = settings;

    return lastJob = ControllablePdfConversionJob();
  }

  @override
  Future<void> discard(List<ConvertedFile> files) async {
    discarded.addAll(files);
  }
}

/// A run the test drives by hand.
class ControllablePdfConversionJob implements PdfConversionJob {
  final StreamController<PdfConversionUpdate> _controller =
      StreamController<PdfConversionUpdate>.broadcast();

  bool wasCancelled = false;

  @override
  Stream<PdfConversionUpdate> get updates => _controller.stream;

  void progress({required int done, required int total}) =>
      _controller.add(PdfProgressed(done: done, total: total));

  void produce(String name, {int sizeInBytes = 1024}) => _controller.add(
        PdfFileProduced(
          ConvertedFile(
            name: name,
            path: '/tmp/archonex_pdf_test/$name',
            sizeInBytes: sizeInBytes,
          ),
        ),
      );

  /// This, and only this, is what says a run is over.
  Future<void> finish() => _controller.close();

  Future<void> fail([
    ConversionFailure failure = const ConversionEngineFailure(),
  ]) async {
    _controller.addError(failure);

    return _controller.close();
  }

  @override
  Future<void> cancel() async {
    wasCancelled = true;
    _controller.addError(const ConversionCancelledFailure());

    return _controller.close();
  }
}

/// A picked file with a plausible path, so deduplication behaves as in the app.
SourceFile source(String name, {int sizeInBytes = 1024}) => SourceFile(
      name: name,
      sizeInBytes: sizeInBytes,
      path: '/tmp/sources/$name',
    );
