import 'package:flutter_test/flutter_test.dart';

import 'package:archonex_converter/core/constants/app_file_limits.dart';
import 'package:archonex_converter/project_files/features/converter_shared/domain/models/conversion_failure.dart';
import 'package:archonex_converter/project_files/features/converter_shared/domain/models/source_file.dart';
import 'package:archonex_converter/project_files/features/media_converter/data/use_cases/convert_media_use_case.dart';
import 'package:archonex_converter/project_files/features/media_converter/data/use_cases/discard_converted_file_use_case.dart';
import 'package:archonex_converter/project_files/features/media_converter/data/use_cases/get_converter_availability_use_case.dart';
import 'package:archonex_converter/project_files/features/media_converter/data/use_cases/pick_source_file_use_case.dart';
import 'package:archonex_converter/project_files/features/media_converter/data/use_cases/save_converted_file_use_case.dart';
import 'package:archonex_converter/project_files/features/media_converter/domain/models/audio_bitrate_option.dart';
import 'package:archonex_converter/project_files/features/media_converter/domain/models/conversion_quality.dart';
import 'package:archonex_converter/project_files/features/media_converter/domain/models/frame_rate_option.dart';
import 'package:archonex_converter/project_files/features/media_converter/domain/models/media_format.dart';
import 'package:archonex_converter/project_files/features/media_converter/domain/models/video_resolution.dart';
import 'package:archonex_converter/project_files/features/media_converter/ui/bloc/media_converter_bloc.dart';

import 'fakes.dart';

void main() {
  late FakeMediaFileRepo fileRepo;
  late FakeMediaConverterRepo converterRepo;
  late MediaConverterBloc bloc;

  // A MOV rather than an MP4, so MP4 itself is a legal target: no format is
  // ever offered as a conversion of itself.
  const SourceFile videoSource = SourceFile(
    name: 'clip.mov',
    sizeInBytes: 5 * 1024 * 1024,
    path: '/tmp/clip.mov',
  );
  const SourceFile otherVideoSource = SourceFile(
    name: 'other.mp4',
    sizeInBytes: 1024 * 1024,
    path: '/tmp/other.mp4',
  );
  const SourceFile audioSource = SourceFile(
    name: 'song.mp3',
    sizeInBytes: 1024 * 1024,
    path: '/tmp/song.mp3',
  );

  /// Rebuilds the bloc so a test can start from a different platform support
  /// state; called with the defaults by [setUp].
  void buildBloc({bool isSupported = true}) {
    fileRepo = FakeMediaFileRepo();
    converterRepo = FakeMediaConverterRepo(isSupported: isSupported);
    bloc = MediaConverterBloc(
      getConverterAvailability: GetConverterAvailabilityUseCase(converterRepo),
      pickSourceFile: PickSourceFileUseCase(fileRepo),
      convertMedia: ConvertMediaUseCase(converterRepo),
      saveConvertedFile: SaveConvertedFileUseCase(fileRepo),
      discardConvertedFile: DiscardConvertedFileUseCase(converterRepo),
    )..add(const MediaConverterStarted());
  }

  setUp(buildBloc);

  tearDown(() => bloc.close());

  /// Lets the bloc drain its event queue and any awaited futures.
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  /// Picks [file] and selects [target], the state every conversion starts in.
  Future<void> prepare({
    SourceFile file = videoSource,
    MediaFormat target = MediaFormat.gif,
  }) async {
    fileRepo.pickResult = file;
    bloc.add(const SourceFilePickRequested());
    await settle();

    bloc.add(TargetFormatSelected(target));
    await settle();
  }

  group('picking', () {
    test('starts with nothing chosen and nothing offered', () {
      expect(bloc.state.status, MediaConverterStatus.idle);
      expect(bloc.state.source, isNull);
      expect(bloc.state.target, isNull);
      expect(bloc.state.availableTargets, isEmpty);
      expect(bloc.state.failure, isNull);
    });

    test('a valid pick lists the reachable formats but cannot convert yet',
        () async {
      fileRepo.pickResult = videoSource;

      bloc.add(const SourceFilePickRequested());
      await settle();

      expect(bloc.state.status, MediaConverterStatus.ready);
      expect(bloc.state.source, videoSource);
      expect(bloc.state.availableTargets, contains(MediaFormat.gif));
      expect(bloc.state.availableTargets, contains(MediaFormat.mp3));
      // No target yet: the screen knows the file but not what to make of it.
      expect(bloc.state.canConvert, isFalse);
    });

    test('the source format is never offered as a target', () async {
      fileRepo.pickResult = videoSource;

      bloc.add(const SourceFilePickRequested());
      await settle();

      expect(bloc.state.availableTargets, isNot(contains(MediaFormat.mov)));
      expect(bloc.state.availableTargets, contains(MediaFormat.mp4));
    });

    test('an audio pick offers audio formats only', () async {
      fileRepo.pickResult = audioSource;

      bloc.add(const SourceFilePickRequested());
      await settle();

      expect(
        bloc.state.availableTargets.every((format) => format.isAudio),
        isTrue,
      );
    });

    test('choosing a target makes the screen convertible', () async {
      await prepare();

      expect(bloc.state.target, MediaFormat.gif);
      expect(bloc.state.canConvert, isTrue);
    });

    test('a second file of a compatible family keeps the chosen target',
        () async {
      await prepare(target: MediaFormat.webm);

      fileRepo.pickResult = otherVideoSource;
      bloc.add(const SourceFilePickRequested());
      await settle();

      expect(bloc.state.source, otherVideoSource);
      expect(bloc.state.target, MediaFormat.webm);
    });

    test('a file that cannot reach the chosen target clears it', () async {
      await prepare(target: MediaFormat.webm);

      fileRepo.pickResult = audioSource;
      bloc.add(const SourceFilePickRequested());
      await settle();

      expect(bloc.state.target, isNull);
      expect(bloc.state.canConvert, isFalse);
    });

    test('an unknown extension clears the source and reports the failure',
        () async {
      fileRepo.pickResult = const SourceFile(
        name: 'art.psd',
        sizeInBytes: 1024,
      );

      bloc.add(const SourceFilePickRequested());
      await settle();

      expect(bloc.state.failure, isA<UnsupportedFormatFailure>());
      expect(bloc.state.source, isNull);
      expect(bloc.state.availableTargets, isEmpty);
    });

    test('an oversized pick lands in state.failure and keeps no source',
        () async {
      fileRepo.pickResult = SourceFile(
        name: 'huge.mp4',
        sizeInBytes: AppFileLimits.maxUploadBytes + 1,
      );

      bloc.add(const SourceFilePickRequested());
      await settle();

      expect(bloc.state.failure, isA<FileTooLargeFailure>());
      expect(bloc.state.source, isNull);
      expect(bloc.state.canConvert, isFalse);
      expect(bloc.state.status, MediaConverterStatus.idle);
    });

    test('a cancelled picker leaves the previous state untouched', () async {
      await prepare(target: MediaFormat.webm);

      fileRepo.pickResult = null;
      bloc.add(const SourceFilePickRequested());
      await settle();

      expect(bloc.state.status, MediaConverterStatus.ready);
      expect(bloc.state.source, videoSource);
      expect(bloc.state.target, MediaFormat.webm);
      expect(bloc.state.failure, isNull);
    });

    test('removing the file resets the screen', () async {
      await prepare();

      bloc.add(const SourceFileCleared());
      await settle();

      expect(bloc.state.status, MediaConverterStatus.idle);
      expect(bloc.state.source, isNull);
      expect(bloc.state.target, isNull);
      expect(bloc.state.availableTargets, isEmpty);
    });
  });

  group('settings', () {
    test('re-selecting the same target changes nothing', () async {
      await prepare();
      final MediaConverterState before = bloc.state;

      bloc.add(const TargetFormatSelected(MediaFormat.gif));
      await settle();

      expect(bloc.state, before);
      expect(converterRepo.discarded, isEmpty);
    });

    test('a target that is not on offer is ignored', () async {
      await prepare(file: audioSource, target: MediaFormat.wav);

      bloc.add(const TargetFormatSelected(MediaFormat.mp4));
      await settle();

      expect(bloc.state.target, MediaFormat.wav);
    });

    test('switching target drops overrides the new format cannot use',
        () async {
      await prepare(target: MediaFormat.mkv);

      bloc
        ..add(const FrameRateChanged(FrameRateOption.fps24))
        ..add(const VideoQualityChanged(90));
      await settle();

      bloc.add(const TargetFormatSelected(MediaFormat.wav));
      await settle();

      expect(bloc.state.settings.frameRate, FrameRateOption.auto);
      expect(bloc.state.settings.videoQuality, isNull);
    });

    test('switching target keeps overrides the new format still uses',
        () async {
      await prepare(target: MediaFormat.mkv);

      bloc.add(const VideoQualityChanged(90));
      await settle();

      bloc.add(const TargetFormatSelected(MediaFormat.mp4));
      await settle();

      expect(bloc.state.settings.videoQuality, 90);
    });

    test('changing the quality preset clears every override', () async {
      await prepare(target: MediaFormat.mp4);

      bloc
        ..add(const ResolutionChanged(VideoResolution.hd))
        ..add(const AudioBitrateChanged(AudioBitrateOption.kbps320));
      await settle();

      bloc.add(const QualityPresetChanged(ConversionQuality.high));
      await settle();

      expect(bloc.state.settings.quality, ConversionQuality.high);
      expect(bloc.state.settings.isPresetOnly, isTrue);
    });

    test('the reset button puts the preset back in charge', () async {
      await prepare(target: MediaFormat.mp4);

      bloc.add(const ResolutionChanged(VideoResolution.hd));
      await settle();
      expect(bloc.state.settings.isPresetOnly, isFalse);

      bloc.add(const AdvancedSettingsReset());
      await settle();

      expect(bloc.state.settings.isPresetOnly, isTrue);
    });

    test('an out of range quality is clamped rather than stored', () async {
      await prepare(target: MediaFormat.mp4);

      bloc.add(const VideoQualityChanged(500));
      await settle();

      expect(
        bloc.state.settings.videoQuality,
        ConversionQuality.maxVideoQuality,
      );
    });

    test('a setting that resolves to the same value discards nothing',
        () async {
      await prepare(target: MediaFormat.mp4);
      await _convertAndComplete(bloc, converterRepo, settle);

      bloc.add(const ResolutionChanged(VideoResolution.auto));
      await settle();

      expect(converterRepo.discarded, isEmpty);
      expect(bloc.state.result, isNotNull);
    });

    test('a real setting change throws the stale result away', () async {
      await prepare(target: MediaFormat.mp4);
      await _convertAndComplete(bloc, converterRepo, settle);

      bloc.add(const ResolutionChanged(VideoResolution.hd));
      await settle();

      expect(converterRepo.discarded, hasLength(1));
      expect(bloc.state.result, isNull);
      expect(bloc.state.status, MediaConverterStatus.ready);
    });

    test('toggling the advanced panel leaves the result alone', () async {
      await prepare();
      await _convertAndComplete(bloc, converterRepo, settle);

      bloc.add(const AdvancedPanelToggled());
      await settle();

      expect(bloc.state.isAdvancedExpanded, isTrue);
      expect(bloc.state.result, isNotNull);
      expect(converterRepo.discarded, isEmpty);
    });
  });

  group('converting', () {
    test('is refused while no target is chosen', () async {
      fileRepo.pickResult = videoSource;
      bloc.add(const SourceFilePickRequested());
      await settle();

      bloc.add(const ConversionRequested());
      await settle();

      expect(converterRepo.convertCallCount, 0);
    });

    test('reports progress and then the result', () async {
      await prepare();

      bloc.add(const ConversionRequested());
      await settle();

      expect(bloc.state.status, MediaConverterStatus.converting);

      converterRepo.lastJob!.emitProgress(0.5);
      await settle();
      expect(bloc.state.progress, 0.5);

      await converterRepo.lastJob!.complete();
      await settle();

      expect(bloc.state.status, MediaConverterStatus.converted);
      expect(bloc.state.result?.name, 'clip.gif');
      expect(bloc.state.progress, 1);
    });

    test('hands the engine the chosen target and settings', () async {
      await prepare(target: MediaFormat.webm);

      bloc.add(const QualityPresetChanged(ConversionQuality.high));
      await settle();

      bloc.add(const ConversionRequested());
      await settle();

      expect(converterRepo.lastTarget, MediaFormat.webm);
      expect(converterRepo.lastSettings?.quality, ConversionQuality.high);
    });

    test('a second request during a run is dropped', () async {
      await prepare();

      bloc
        ..add(const ConversionRequested())
        ..add(const ConversionRequested());
      await settle();

      expect(converterRepo.convertCallCount, 1);
    });

    test('settings are frozen while a run is in flight', () async {
      await prepare();

      bloc.add(const ConversionRequested());
      await settle();

      bloc.add(const QualityPresetChanged(ConversionQuality.high));
      await settle();

      expect(bloc.state.settings.quality, ConversionQuality.balanced);
    });

    test('cancelling surfaces the cancelled notice', () async {
      await prepare();

      bloc.add(const ConversionRequested());
      await settle();

      bloc.add(const ConversionCancelled());
      await settle();

      expect(converterRepo.lastJob!.wasCancelled, isTrue);
      expect(bloc.state.failure, isA<ConversionCancelledFailure>());
      expect(bloc.state.status, MediaConverterStatus.ready);
      expect(bloc.state.result, isNull);
    });

    test('an engine failure surfaces without losing the source', () async {
      await prepare();

      bloc.add(const ConversionRequested());
      await settle();

      await converterRepo.lastJob!.fail();
      await settle();

      expect(bloc.state.failure, isA<ConversionEngineFailure>());
      expect(bloc.state.source, videoSource);
      expect(bloc.state.canConvert, isTrue);
    });

    test('an unknown duration reaches state as indeterminate progress',
        () async {
      await prepare();

      bloc.add(const ConversionRequested());
      await settle();

      converterRepo.lastJob!.emitProgress(null);
      await settle();

      expect(bloc.state.isConverting, isTrue);
      expect(bloc.state.progress, isNull);
    });
  });

  group('saving', () {
    test('records the location the platform reports', () async {
      fileRepo.saveLocation = r'C:\Users\me\clip.gif';
      await prepare();
      await _convertAndComplete(bloc, converterRepo, settle);

      bloc.add(const ConvertedFileSaveRequested());
      await settle();

      expect(bloc.state.status, MediaConverterStatus.saved);
      expect(bloc.state.savedLocation, r'C:\Users\me\clip.gif');
    });

    test('a null location counts as success where none is reported', () async {
      fileRepo
        ..saveLocation = null
        ..reportsSaveLocation = false;
      await prepare();
      await _convertAndComplete(bloc, converterRepo, settle);

      bloc.add(const ConvertedFileSaveRequested());
      await settle();

      expect(bloc.state.status, MediaConverterStatus.saved);
      expect(bloc.state.savedLocation, isNull);
    });

    test('a cancelled save dialog is not an error', () async {
      fileRepo.saveLocation = null;
      await prepare();
      await _convertAndComplete(bloc, converterRepo, settle);

      bloc.add(const ConvertedFileSaveRequested());
      await settle();

      expect(bloc.state.status, MediaConverterStatus.converted);
      expect(bloc.state.failure, isNull);
    });

    test('a failed save surfaces and keeps the result downloadable', () async {
      fileRepo.saveError = const SavePermissionDeniedFailure();
      await prepare();
      await _convertAndComplete(bloc, converterRepo, settle);

      bloc.add(const ConvertedFileSaveRequested());
      await settle();

      expect(bloc.state.failure, isA<SavePermissionDeniedFailure>());
      expect(bloc.state.status, MediaConverterStatus.converted);
      expect(bloc.state.result, isNotNull);
    });
  });

  group('temp files', () {
    test('a superseded result is discarded so no temp file leaks', () async {
      await prepare();
      await _convertAndComplete(bloc, converterRepo, settle);

      final String firstResultPath = bloc.state.result!.path;

      bloc.add(const SourceFileCleared());
      await settle();

      expect(converterRepo.discarded.single.path, firstResultPath);
      expect(bloc.state.result, isNull);
    });

    test('closing the bloc discards an unsaved result', () async {
      await prepare();
      await _convertAndComplete(bloc, converterRepo, settle);

      await bloc.close();

      expect(converterRepo.discarded, hasLength(1));
    });
  });

  test('an unsupported platform blocks picking, editing and converting',
      () async {
    buildBloc(isSupported: false);
    await settle();

    expect(bloc.state.isSupported, isFalse);
    expect(bloc.state.canPick, isFalse);
    expect(bloc.state.canEditSettings, isFalse);
    expect(bloc.state.canConvert, isFalse);
  });
}

/// Runs a conversion through to a finished result.
Future<void> _convertAndComplete(
  MediaConverterBloc bloc,
  FakeMediaConverterRepo repo,
  Future<void> Function() settle,
) async {
  bloc.add(const ConversionRequested());
  await settle();
  await repo.lastJob!.complete();
  await settle();
}
