import 'dart:async';

import 'package:archonex/project_files/features/converter_shared/domain/models/conversion_failure.dart';
import 'package:archonex/project_files/features/converter_shared/domain/models/converted_file.dart';
import 'package:archonex/project_files/features/converter_shared/domain/models/save_result.dart';
import 'package:archonex/project_files/features/converter_shared/domain/models/source_file.dart';
import 'package:archonex/project_files/features/image_converter/domain/image_converter_repo.dart';
import 'package:archonex/project_files/features/image_converter/domain/image_file_repo.dart';
import 'package:archonex/project_files/features/image_converter/domain/models/image_conversion_job.dart';
import 'package:archonex/project_files/features/image_converter/domain/models/image_conversion_settings.dart';
import 'package:archonex/project_files/features/image_converter/domain/models/image_conversion_update.dart';
import 'package:archonex/project_files/features/image_converter/domain/models/image_format.dart';

/// Image file access driven entirely by the test.
class FakeImageFileRepo implements ImageFileRepo {
  FakeImageFileRepo({
    this.pickResult = const <SourceFile>[],
    this.pickError,
    this.saveLocation,
    this.saveError,
    this.saveAllResult,
    this.saveAllError,
    this.reportsSaveLocation = true,
  });

  List<SourceFile> pickResult;
  ConversionFailure? pickError;
  String? saveLocation;
  ConversionFailure? saveError;
  SaveResult? saveAllResult;
  ConversionFailure? saveAllError;

  @override
  bool reportsSaveLocation;

  int pickCallCount = 0;
  int saveCallCount = 0;
  int saveAllCallCount = 0;

  /// What the last [saveAllConverted] was asked to write.
  List<ConvertedFile> lastSavedAll = const <ConvertedFile>[];

  @override
  Future<List<SourceFile>> pickSources() async {
    pickCallCount++;
    final ConversionFailure? error = pickError;
    if (error != null) {
      throw error;
    }

    return pickResult;
  }

  @override
  Future<String?> saveConverted(ConvertedFile file) async {
    saveCallCount++;
    final ConversionFailure? error = saveError;
    if (error != null) {
      throw error;
    }

    return saveLocation;
  }

  @override
  Future<SaveResult> saveAllConverted(List<ConvertedFile> files) async {
    saveAllCallCount++;
    lastSavedAll = files;

    final ConversionFailure? error = saveAllError;
    if (error != null) {
      throw error;
    }

    return saveAllResult ??
        SaveResult(
          outcome: SaveOutcome.savedToLocation,
          location: '/tmp/pictures',
          savedCount: files.length,
        );
  }
}

/// Converter engine whose batch is stepped manually by the test.
class FakeImageConverterRepo implements ImageConverterRepo {
  FakeImageConverterRepo({this.isSupported = true});

  @override
  bool isSupported;

  ControllableImageConversionJob? lastJob;
  List<SourceFile>? lastSources;
  ImageFormat? lastTarget;
  ImageConversionSettings? lastSettings;
  int convertCallCount = 0;

  /// Results handed to [discard], newest last.
  final List<ConvertedFile> discarded = <ConvertedFile>[];

  @override
  ImageConversionJob convert({
    required List<SourceFile> sources,
    required ImageFormat target,
    required ImageConversionSettings settings,
  }) {
    convertCallCount++;
    lastSources = sources;
    lastTarget = target;
    lastSettings = settings;

    final ControllableImageConversionJob job = ControllableImageConversionJob(
      sources: sources,
      target: target,
    );
    lastJob = job;

    return job;
  }

  @override
  Future<void> discard(List<ConvertedFile> files) async =>
      discarded.addAll(files);
}

class ControllableImageConversionJob implements ImageConversionJob {
  ControllableImageConversionJob({
    required this.sources,
    required this.target,
  });

  final List<SourceFile> sources;
  final ImageFormat target;

  final StreamController<ImageConversionUpdate> _controller =
      StreamController<ImageConversionUpdate>.broadcast();

  bool wasCancelled = false;

  @override
  Stream<ImageConversionUpdate> get updates => _controller.stream;

  @override
  Future<void> cancel() async {
    wasCancelled = true;
    if (_controller.isClosed) {
      return;
    }

    _controller.addError(const ConversionCancelledFailure());
    await _controller.close();
  }

  void start(int index) => _controller.add(ImageItemStarted(index));

  void emitConverted(int index, {int sizeInBytes = 1024}) {
    final String name =
        '${sources[index].baseName}.${target.extension}';

    _controller.add(
      ImageItemConverted(
        index,
        ConvertedFile(
          name: name,
          path: '/tmp/archonex_images_test/${index}_$name',
          sizeInBytes: sizeInBytes,
        ),
      ),
    );
  }

  void emitFailed(
    int index, [
    ConversionFailure failure = const ConversionEngineFailure(),
  ]) =>
      _controller.add(ImageItemFailed(index, failure));

  /// The queue reached the end — this, and only this, is what says a batch is
  /// over.
  Future<void> finish() => _controller.close();

  Future<void> fail() async {
    _controller.addError(const ConversionEngineFailure());
    await _controller.close();
  }
}
