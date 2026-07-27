import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:archonex_converter/core/constants/app_file_limits.dart';
import 'package:archonex_converter/project_files/features/converter_shared/domain/models/conversion_failure.dart';
import 'package:archonex_converter/project_files/features/converter_shared/domain/models/save_result.dart';
import 'package:archonex_converter/project_files/features/converter_shared/domain/models/source_file.dart';
import 'package:archonex_converter/project_files/features/image_converter/data/use_cases/convert_images_use_case.dart';
import 'package:archonex_converter/project_files/features/image_converter/data/use_cases/discard_converted_images_use_case.dart';
import 'package:archonex_converter/project_files/features/image_converter/data/use_cases/get_image_converter_availability_use_case.dart';
import 'package:archonex_converter/project_files/features/image_converter/data/use_cases/pick_source_images_use_case.dart';
import 'package:archonex_converter/project_files/features/image_converter/data/use_cases/save_all_converted_images_use_case.dart';
import 'package:archonex_converter/project_files/features/image_converter/data/use_cases/save_converted_image_use_case.dart';
import 'package:archonex_converter/project_files/features/image_converter/domain/models/image_background.dart';
import 'package:archonex_converter/project_files/features/image_converter/domain/models/image_conversion_item.dart';
import 'package:archonex_converter/project_files/features/image_converter/domain/models/image_dimension_limit.dart';
import 'package:archonex_converter/project_files/features/image_converter/domain/models/image_format.dart';
import 'package:archonex_converter/project_files/features/image_converter/domain/models/image_quality.dart';
import 'package:archonex_converter/project_files/features/image_converter/ui/bloc/image_converter_bloc.dart';

import 'fakes.dart';

void main() {
  late FakeImageFileRepo fileRepo;
  late FakeImageConverterRepo converterRepo;
  late ImageConverterBloc bloc;

  const SourceFile onePng = SourceFile(
    name: 'one.png',
    sizeInBytes: 1024,
    path: '/tmp/one.png',
  );
  const SourceFile twoPng = SourceFile(
    name: 'two.png',
    sizeInBytes: 2048,
    path: '/tmp/two.png',
  );
  const SourceFile threeJpg = SourceFile(
    name: 'three.jpg',
    sizeInBytes: 4096,
    path: '/tmp/three.jpg',
  );

  void buildBloc({bool isSupported = true}) {
    fileRepo = FakeImageFileRepo();
    converterRepo = FakeImageConverterRepo(isSupported: isSupported);
    bloc = ImageConverterBloc(
      getConverterAvailability:
          GetImageConverterAvailabilityUseCase(converterRepo),
      pickSourceImages: PickSourceImagesUseCase(fileRepo),
      convertImages: ConvertImagesUseCase(converterRepo),
      saveConvertedImage: SaveConvertedImageUseCase(fileRepo),
      saveAllConvertedImages: SaveAllConvertedImagesUseCase(fileRepo),
      discardConvertedImages: DiscardConvertedImagesUseCase(converterRepo),
    )..add(const ImageConverterStarted());
  }

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    buildBloc();
  });

  tearDown(() async {
    await bloc.close();
    debugDefaultTargetPlatformOverride = null;
  });

  /// Lets the bloc drain its event queue and any awaited futures.
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  /// Adds [files] and selects [target], the state every conversion starts in.
  Future<void> prepare({
    List<SourceFile> files = const <SourceFile>[onePng, twoPng],
    ImageFormat target = ImageFormat.webp,
  }) async {
    fileRepo.pickResult = files;
    bloc.add(const SourceImagesPickRequested());
    await settle();

    bloc.add(TargetFormatSelected(target));
    await settle();
  }

  /// Runs a whole batch to completion, converting every photo in it.
  Future<ControllableImageConversionJob> convertAll() async {
    bloc.add(const ConversionRequested());
    await settle();

    final ControllableImageConversionJob job = converterRepo.lastJob!;

    for (int index = 0; index < bloc.state.totalCount; index++) {
      job
        ..start(index)
        ..emitConverted(index);
      await settle();
    }

    await job.finish();
    await settle();

    return job;
  }

  group('picking', () {
    test('starts with nothing chosen and nothing offered', () {
      expect(bloc.state.status, ImageConverterStatus.idle);
      expect(bloc.state.items, isEmpty);
      expect(bloc.state.target, isNull);
      expect(bloc.state.availableTargets, isEmpty);
      expect(bloc.state.failure, isNull);
    });

    test('a valid pick lists the reachable formats but cannot convert yet',
        () async {
      fileRepo.pickResult = <SourceFile>[onePng, twoPng];

      bloc.add(const SourceImagesPickRequested());
      await settle();

      expect(bloc.state.status, ImageConverterStatus.ready);
      expect(bloc.state.totalCount, 2);
      expect(bloc.state.availableTargets, contains(ImageFormat.webp));
      // No target yet: the screen knows the photos but not what to make of them.
      expect(bloc.state.canConvert, isFalse);
    });

    test('a batch of one format is not offered that format', () async {
      fileRepo.pickResult = <SourceFile>[onePng, twoPng];

      bloc.add(const SourceImagesPickRequested());
      await settle();

      expect(bloc.state.availableTargets, isNot(contains(ImageFormat.png)));
    });

    test('a second pick appends rather than replaces', () async {
      fileRepo.pickResult = <SourceFile>[onePng];
      bloc.add(const SourceImagesPickRequested());
      await settle();

      fileRepo.pickResult = <SourceFile>[twoPng];
      bloc.add(const SourceImagesPickRequested());
      await settle();

      expect(bloc.state.totalCount, 2);
    });

    test('the same file picked twice is held once', () async {
      fileRepo.pickResult = <SourceFile>[onePng];
      bloc.add(const SourceImagesPickRequested());
      await settle();

      bloc.add(const SourceImagesPickRequested());
      await settle();

      expect(bloc.state.totalCount, 1);
    });

    test('a closed dialog leaves the batch alone', () async {
      await prepare();

      fileRepo.pickResult = const <SourceFile>[];
      bloc.add(const SourceImagesPickRequested());
      await settle();

      expect(bloc.state.totalCount, 2);
      expect(bloc.state.target, ImageFormat.webp);
      expect(bloc.state.status, ImageConverterStatus.ready);
    });

    test('a partly unusable pick keeps the rest and says what was dropped',
        () async {
      fileRepo.pickResult = <SourceFile>[
        onePng,
        const SourceFile(name: 'art.psd', sizeInBytes: 1024),
      ];

      bloc.add(const SourceImagesPickRequested());
      await settle();

      expect(bloc.state.totalCount, 1);
      expect(bloc.state.failure, isA<FilesSkippedFailure>());
    });

    test('a wholly unusable pick leaves the screen empty and explains why',
        () async {
      fileRepo.pickResult = <SourceFile>[
        const SourceFile(name: 'art.psd', sizeInBytes: 1024),
      ];

      bloc.add(const SourceImagesPickRequested());
      await settle();

      expect(bloc.state.items, isEmpty);
      expect(bloc.state.status, ImageConverterStatus.idle);
      expect(bloc.state.failure, isA<UnsupportedFormatFailure>());
    });

    test('picking stops being offered once the batch is full', () async {
      fileRepo.pickResult = <SourceFile>[
        for (int i = 0; i < AppFileLimits.maxBatchFiles; i++)
          SourceFile(name: '$i.png', sizeInBytes: 1024, path: '/tmp/$i.png'),
      ];

      bloc.add(const SourceImagesPickRequested());
      await settle();

      expect(bloc.state.canPick, isFalse);
    });
  });

  group('editing the batch', () {
    test('removing a photo keeps the others', () async {
      await prepare();

      bloc.add(const SourceImageRemoved(0));
      await settle();

      expect(bloc.state.totalCount, 1);
      expect(bloc.state.items.single.source, twoPng);
    });

    test('removing the last photo empties the screen', () async {
      await prepare(files: <SourceFile>[onePng]);

      bloc.add(const SourceImageRemoved(0));
      await settle();

      expect(bloc.state.status, ImageConverterStatus.idle);
      expect(bloc.state.target, isNull);
      expect(bloc.state.availableTargets, isEmpty);
    });

    test('a removal that makes the target unreachable drops it', () async {
      // A JPG and a PNG can both become JPG; once the PNG is gone, JPG would be
      // a conversion of the batch into itself.
      await prepare(
        files: <SourceFile>[onePng, threeJpg],
        target: ImageFormat.jpg,
      );
      expect(bloc.state.target, ImageFormat.jpg);

      bloc.add(const SourceImageRemoved(0));
      await settle();

      expect(bloc.state.target, isNull);
    });

    test('clearing resets everything but the panel preference', () async {
      await prepare();
      bloc.add(const AdvancedPanelToggled());
      await settle();

      bloc.add(const SourceImagesCleared());
      await settle();

      expect(bloc.state.items, isEmpty);
      expect(bloc.state.target, isNull);
      expect(bloc.state.isAdvancedExpanded, isTrue);
    });
  });

  group('settings', () {
    test('a target the batch cannot reach is ignored', () async {
      await prepare();

      bloc.add(const TargetFormatSelected(ImageFormat.heic));
      await settle();

      expect(bloc.state.target, ImageFormat.webp);
    });

    test('moving the preset clears the overrides under it', () async {
      await prepare();

      bloc.add(const ImageQualityChanged(35));
      await settle();
      expect(bloc.state.settings.isPresetOnly, isFalse);

      bloc.add(const QualityPresetChanged(ImageQuality.compact));
      await settle();

      expect(bloc.state.settings.quality, ImageQuality.compact);
      expect(bloc.state.settings.isPresetOnly, isTrue);
    });

    test('the quality override is clamped to the scale', () async {
      await prepare();

      bloc.add(const ImageQualityChanged(500));
      await settle();

      expect(bloc.state.settings.imageQuality, ImageQuality.maxQuality);
    });

    test('a target that ignores a field prunes it out of state', () async {
      // Mixed batch, so PNG is a real target rather than a no-op.
      await prepare(files: <SourceFile>[onePng, threeJpg]);

      bloc.add(const ImageQualityChanged(35));
      await settle();
      expect(bloc.state.settings.imageQuality, 35);

      bloc.add(const TargetFormatSelected(ImageFormat.png));
      await settle();

      expect(bloc.state.target, ImageFormat.png);
      expect(bloc.state.settings.imageQuality, isNull);
    });

    test('the backdrop is only a question when transparency is lost', () async {
      await prepare(target: ImageFormat.webp);
      expect(bloc.state.needsBackgroundChoice, isFalse);

      bloc.add(const TargetFormatSelected(ImageFormat.jpg));
      await settle();

      expect(bloc.state.needsBackgroundChoice, isTrue);
    });

    test('resetting returns to the preset alone', () async {
      await prepare();

      bloc.add(const DimensionLimitChanged(ImageDimensionLimit.px800));
      await settle();
      bloc.add(const KeepMetadataToggled(true));
      await settle();

      bloc.add(const AdvancedSettingsReset());
      await settle();

      expect(bloc.state.settings.isPresetOnly, isTrue);
    });

    test('settings cannot be touched while a batch is running', () async {
      await prepare();
      bloc.add(const ConversionRequested());
      await settle();

      bloc.add(const DimensionLimitChanged(ImageDimensionLimit.px800));
      await settle();

      expect(
        bloc.state.settings.dimensionLimit,
        ImageDimensionLimit.auto,
      );
    });
  });

  group('converting', () {
    test('walks the batch and reports progress as it goes', () async {
      await prepare();

      bloc.add(const ConversionRequested());
      await settle();

      expect(bloc.state.status, ImageConverterStatus.converting);
      expect(bloc.state.progress, 0);

      final ControllableImageConversionJob job = converterRepo.lastJob!;

      job
        ..start(0)
        ..emitConverted(0);
      await settle();

      expect(bloc.state.progress, 0.5);
      expect(bloc.state.items.first.status, ImageItemStatus.done);
      expect(bloc.state.items.last.status, ImageItemStatus.pending);

      job.emitConverted(1);
      await settle();
      await job.finish();
      await settle();

      expect(bloc.state.status, ImageConverterStatus.converted);
      expect(bloc.state.progress, 1);
      expect(bloc.state.convertedCount, 2);
    });

    test('one bad photo fails alone and the rest still convert', () async {
      await prepare();

      bloc.add(const ConversionRequested());
      await settle();

      final ControllableImageConversionJob job = converterRepo.lastJob!;
      job.emitFailed(0, const CorruptSourceFailure());
      await settle();
      job.emitConverted(1);
      await settle();
      await job.finish();
      await settle();

      expect(bloc.state.status, ImageConverterStatus.converted);
      expect(bloc.state.failedCount, 1);
      expect(bloc.state.convertedCount, 1);
      expect(bloc.state.items.first.failure, isA<CorruptSourceFailure>());
      // A per photo problem is not the batch's problem.
      expect(bloc.state.failure, isNull);
      expect(bloc.state.hasResults, isTrue);
    });

    test('cancelling mid batch stops the queue and keeps nothing', () async {
      await prepare();

      bloc.add(const ConversionRequested());
      await settle();

      final ControllableImageConversionJob job = converterRepo.lastJob!;
      job.emitConverted(0);
      await settle();

      bloc.add(const ConversionCancelled());
      await settle();

      expect(job.wasCancelled, isTrue);
      expect(bloc.state.status, ImageConverterStatus.ready);
      expect(bloc.state.failure, isA<ConversionCancelledFailure>());
      expect(bloc.state.hasResults, isFalse);
    });

    test('an engine failure parks the screen back where it can act', () async {
      await prepare();

      bloc.add(const ConversionRequested());
      await settle();

      await converterRepo.lastJob!.fail();
      await settle();

      expect(bloc.state.status, ImageConverterStatus.ready);
      expect(bloc.state.failure, isA<ConversionEngineFailure>());
      expect(bloc.state.totalCount, 2);
    });

    test('a second request while one runs is ignored', () async {
      await prepare();

      bloc
        ..add(const ConversionRequested())
        ..add(const ConversionRequested());
      await settle();

      expect(converterRepo.convertCallCount, 1);
    });
  });

  group('temporary files', () {
    test('a settings change throws the whole batch of results away', () async {
      await prepare();
      await convertAll();
      expect(bloc.state.convertedCount, 2);

      bloc.add(const QualityPresetChanged(ImageQuality.compact));
      await settle();

      expect(converterRepo.discarded, hasLength(2));
      expect(bloc.state.hasResults, isFalse);
      expect(bloc.state.status, ImageConverterStatus.ready);
    });

    test('a settings change that changes nothing keeps the results', () async {
      await prepare();
      await convertAll();

      // Already the default, so the batch is still valid.
      bloc.add(const BackgroundChanged(ImageBackground.white));
      await settle();

      expect(converterRepo.discarded, isEmpty);
      expect(bloc.state.convertedCount, 2);
    });

    test('changing the target throws the results away', () async {
      await prepare();
      await convertAll();

      bloc.add(const TargetFormatSelected(ImageFormat.jpg));
      await settle();

      expect(converterRepo.discarded, hasLength(2));
    });

    test('closing the screen releases whatever is left', () async {
      await prepare();
      await convertAll();

      await bloc.close();

      expect(converterRepo.discarded, hasLength(2));
    });
  });

  group('saving', () {
    test('one result reports where it landed', () async {
      await prepare();
      await convertAll();

      fileRepo.saveLocation = '/pictures/one.webp';
      bloc.add(const ConvertedImageSaveRequested(0));
      await settle();

      expect(bloc.state.status, ImageConverterStatus.saved);
      expect(bloc.state.savedLocation, '/pictures/one.webp');
      expect(bloc.state.savedCount, 1);
    });

    test('the whole batch goes out in one call', () async {
      await prepare();
      await convertAll();

      bloc.add(const AllConvertedImagesSaveRequested());
      await settle();

      expect(fileRepo.saveAllCallCount, 1);
      expect(fileRepo.lastSavedAll, hasLength(2));
      expect(bloc.state.status, ImageConverterStatus.saved);
      expect(bloc.state.savedCount, 2);
    });

    test('a cancelled save leaves the results where they were', () async {
      await prepare();
      await convertAll();

      fileRepo.saveAllResult = const SaveResult.cancelled();
      bloc.add(const AllConvertedImagesSaveRequested());
      await settle();

      expect(bloc.state.status, ImageConverterStatus.converted);
      expect(bloc.state.hasResults, isTrue);
      expect(bloc.state.failure, isNull);
    });

    test('a failed save is reported without losing the results', () async {
      await prepare();
      await convertAll();

      fileRepo.saveAllError = const SavePermissionDeniedFailure();
      bloc.add(const AllConvertedImagesSaveRequested());
      await settle();

      expect(bloc.state.status, ImageConverterStatus.converted);
      expect(bloc.state.failure, isA<SavePermissionDeniedFailure>());
      expect(bloc.state.hasResults, isTrue);
    });

    test('nothing is asked of the platform when there is nothing to save',
        () async {
      await prepare();

      bloc.add(const AllConvertedImagesSaveRequested());
      await settle();

      expect(fileRepo.saveAllCallCount, 0);
    });
  });

  group('an unsupported platform', () {
    setUp(() => buildBloc(isSupported: false));

    test('says so and refuses to pick or convert', () async {
      await settle();

      expect(bloc.state.isSupported, isFalse);
      expect(bloc.state.canPick, isFalse);
      expect(bloc.state.canConvert, isFalse);
      expect(bloc.state.canEditSettings, isFalse);
    });
  });
}
