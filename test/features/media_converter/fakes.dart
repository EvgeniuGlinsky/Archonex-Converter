import 'dart:async';

import 'package:archonex/project_files/features/media_converter/domain/media_converter_repo.dart';
import 'package:archonex/project_files/features/media_converter/domain/media_file_repo.dart';
import 'package:archonex/project_files/features/media_converter/domain/models/conversion_failure.dart';
import 'package:archonex/project_files/features/media_converter/domain/models/conversion_job.dart';
import 'package:archonex/project_files/features/media_converter/domain/models/conversion_settings.dart';
import 'package:archonex/project_files/features/media_converter/domain/models/conversion_update.dart';
import 'package:archonex/project_files/features/media_converter/domain/models/converted_file.dart';
import 'package:archonex/project_files/features/media_converter/domain/models/media_format.dart';
import 'package:archonex/project_files/features/media_converter/domain/models/source_file.dart';

/// Media file access driven entirely by the test.
class FakeMediaFileRepo implements MediaFileRepo {
  FakeMediaFileRepo({
    this.pickResult,
    this.pickError,
    this.saveLocation,
    this.saveError,
    this.reportsSaveLocation = true,
  });

  SourceFile? pickResult;
  ConversionFailure? pickError;
  String? saveLocation;
  ConversionFailure? saveError;

  @override
  bool reportsSaveLocation;

  int pickCallCount = 0;
  int saveCallCount = 0;

  @override
  Future<SourceFile?> pickSource() async {
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
}

/// Converter engine whose job is stepped manually by the test.
class FakeMediaConverterRepo implements MediaConverterRepo {
  FakeMediaConverterRepo({this.isSupported = true});

  @override
  bool isSupported;

  ControllableConversionJob? lastJob;
  MediaFormat? lastTarget;
  ConversionSettings? lastSettings;
  int convertCallCount = 0;

  /// Results handed to [discard], newest last.
  final List<ConvertedFile> discarded = <ConvertedFile>[];

  @override
  ConversionJob convert({
    required SourceFile source,
    required MediaFormat target,
    required ConversionSettings settings,
  }) {
    convertCallCount++;
    lastTarget = target;
    lastSettings = settings;

    final ControllableConversionJob job = ControllableConversionJob(
      output: ConvertedFile(
        name: '${source.baseName}.${target.extension}',
        path: '/tmp/archonex_convert_test/'
            '${source.baseName}.${target.extension}',
        sizeInBytes: 2048,
      ),
    );
    lastJob = job;

    return job;
  }

  @override
  Future<void> discard(ConvertedFile file) async => discarded.add(file);
}

class ControllableConversionJob implements ConversionJob {
  ControllableConversionJob({required this.output});

  final ConvertedFile output;
  final StreamController<ConversionUpdate> _controller =
      StreamController<ConversionUpdate>.broadcast();

  bool wasCancelled = false;

  @override
  Stream<ConversionUpdate> get updates => _controller.stream;

  @override
  Future<void> cancel() async {
    wasCancelled = true;
    if (_controller.isClosed) {
      return;
    }

    _controller.addError(const ConversionCancelledFailure());
    await _controller.close();
  }

  void emitProgress(double? value) =>
      _controller.add(ConversionProgress(value));

  Future<void> complete() async {
    _controller.add(ConversionCompleted(output));
    await _controller.close();
  }

  Future<void> fail() async {
    _controller.addError(const ConversionEngineFailure());
    await _controller.close();
  }
}
