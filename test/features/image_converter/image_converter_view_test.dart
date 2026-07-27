import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:archonex_converter/core/constants/app_file_limits.dart';
import 'package:archonex_converter/core/theme/app_theme.dart';
import 'package:archonex_converter/core/utils/file_size_formatter.dart';
import 'package:archonex_converter/l10n/app_localizations.dart';
import 'package:archonex_converter/project_files/features/converter_shared/domain/models/source_file.dart';
import 'package:archonex_converter/project_files/features/image_converter/data/use_cases/convert_images_use_case.dart';
import 'package:archonex_converter/project_files/features/image_converter/data/use_cases/discard_converted_images_use_case.dart';
import 'package:archonex_converter/project_files/features/image_converter/data/use_cases/get_image_converter_availability_use_case.dart';
import 'package:archonex_converter/project_files/features/image_converter/data/use_cases/pick_source_images_use_case.dart';
import 'package:archonex_converter/project_files/features/image_converter/data/use_cases/save_all_converted_images_use_case.dart';
import 'package:archonex_converter/project_files/features/image_converter/data/use_cases/save_converted_image_use_case.dart';
import 'package:archonex_converter/project_files/features/image_converter/domain/models/image_format.dart';
import 'package:archonex_converter/project_files/features/image_converter/ui/bloc/image_converter_bloc.dart';
import 'package:archonex_converter/project_files/features/image_converter/ui/image_converter_view.dart';

import 'fakes.dart';

/// The converter cannot be driven through `ArchonexApp`: picking photos needs
/// the system dialog. The screen is therefore pumped over the fakes and driven
/// by events, which is also what lets a pick be simulated at all.
///
/// The bloc is built inside `BlocProvider.create` rather than in `setUp`. A
/// bloc constructed outside the test body belongs to a different async zone,
/// and events added to it from inside `testWidgets` are never delivered — the
/// screen simply never reacts. Letting the provider own it also means the test
/// framework closes it, instead of the test awaiting a close that the fake
/// clock will not advance.
void main() {
  const Map<String, Size> screenSizes = <String, Size>{
    'phone': Size(390, 844),
    'tablet': Size(834, 1112),
    'desktop': Size(1440, 900),
  };

  const Map<String, int> expectedColumns = <String, int>{
    'phone': 3,
    'tablet': 4,
    'desktop': 6,
  };

  /// Tall enough for the whole screen to be laid out at once.
  ///
  /// The body is a `ListView`, so anything below the fold is never built and
  /// `find.text` cannot see it. Tests about *what exists* therefore use a
  /// viewport with room for all of it; the responsive tests below use the real
  /// sizes, which is where the height genuinely matters.
  const Size tallScreen = Size(1440, 2600);

  const List<SourceFile> photos = <SourceFile>[
    SourceFile(name: 'one.png', sizeInBytes: 1024, path: '/tmp/one.png'),
    SourceFile(name: 'two.jpg', sizeInBytes: 2048, path: '/tmp/two.jpg'),
  ];

  late ImageConverterBloc bloc;
  late AppLocalizations en;

  setUpAll(() async {
    en = await AppLocalizations.delegate.load(const Locale('en'));
  });

  ImageConverterBloc createBloc({required bool isSupported}) {
    final FakeImageFileRepo fileRepo = FakeImageFileRepo(pickResult: photos);
    final FakeImageConverterRepo converterRepo = FakeImageConverterRepo(
      isSupported: isSupported,
    );

    return ImageConverterBloc(
      getConverterAvailability:
          GetImageConverterAvailabilityUseCase(converterRepo),
      pickSourceImages: PickSourceImagesUseCase(fileRepo),
      convertImages: ConvertImagesUseCase(converterRepo),
      saveConvertedImage: SaveConvertedImageUseCase(fileRepo),
      saveAllConvertedImages: SaveAllConvertedImagesUseCase(fileRepo),
      discardConvertedImages: DiscardConvertedImagesUseCase(converterRepo),
    )..add(const ImageConverterStarted());
  }

  Future<void> pumpScreen(
    WidgetTester tester, {
    required Size size,
    bool isSupported = true,
  }) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = size;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<ImageConverterBloc>(
          create: (_) => bloc = createBloc(isSupported: isSupported),
          child: const ImageConverterView(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pickPhotos(WidgetTester tester) async {
    bloc.add(const SourceImagesPickRequested());
    await tester.pumpAndSettle();
  }

  Future<void> chooseTarget(WidgetTester tester, ImageFormat target) async {
    bloc.add(TargetFormatSelected(target));
    await tester.pumpAndSettle();
  }

  Future<void> openAdvanced(WidgetTester tester) async {
    bloc.add(const AdvancedPanelToggled());
    await tester.pumpAndSettle();
  }

  testWidgets('shows nothing beyond the empty batch before a pick',
      (WidgetTester tester) async {
    await pumpScreen(tester, size: screenSizes['phone']!);

    expect(find.text(en.addPhotosLabel), findsOneWidget);
    expect(
      find.text(
        en.imageLimitsNotice(
          AppFileLimits.maxBatchFiles,
          AppFileLimits.maxUploadLabel,
        ),
      ),
      findsOneWidget,
    );
    expect(find.text(en.convertToTitle), findsNothing);
    expect(find.text(en.qualityTitle), findsNothing);
    expect(find.text(en.advancedTitle), findsNothing);
  });

  testWidgets('a pick reveals the targets, a target reveals the settings',
      (WidgetTester tester) async {
    await pumpScreen(tester, size: tallScreen);
    await pickPhotos(tester);

    expect(find.text(en.convertToTitle), findsOneWidget);
    expect(find.text('one.png'), findsOneWidget);
    expect(find.text('two.jpg'), findsOneWidget);
    // Quality only makes sense once there is something to produce.
    expect(find.text(en.qualityTitle), findsNothing);

    await chooseTarget(tester, ImageFormat.webp);

    expect(find.text(en.qualityTitle), findsOneWidget);
    expect(find.text(en.advancedTitle), findsOneWidget);
  });

  testWidgets('the batch summary counts the photos and their size',
      (WidgetTester tester) async {
    await pumpScreen(tester, size: tallScreen);
    await pickPhotos(tester);

    final String totalSize = FileSizeFormatter.format(
      photos.fold(0, (sum, photo) => sum + photo.sizeInBytes),
    );

    expect(find.text(en.photosSelected(2, totalSize)), findsOneWidget);
    expect(find.text(en.addMorePhotosLabel), findsOneWidget);
  });

  testWidgets('convert enables only once a target is chosen',
      (WidgetTester tester) async {
    await pumpScreen(tester, size: screenSizes['phone']!);
    await pickPhotos(tester);

    final Finder untargeted = find.widgetWithText(
      FilledButton,
      en.convertLabel,
    );
    expect(tester.widget<FilledButton>(untargeted).onPressed, isNull);

    await chooseTarget(tester, ImageFormat.webp);

    final Finder targeted = find.widgetWithText(
      FilledButton,
      en.convertAllToLabel(2, ImageFormat.webp.label),
    );
    expect(tester.widget<FilledButton>(targeted).onPressed, isNotNull);
  });

  testWidgets('the advanced panel offers only what the target can use',
      (WidgetTester tester) async {
    await pumpScreen(tester, size: tallScreen);
    await pickPhotos(tester);
    await chooseTarget(tester, ImageFormat.webp);
    await openAdvanced(tester);

    // WebP is lossy and keeps transparency: quality yes, backdrop no.
    expect(find.text(en.maxSideLabel), findsOneWidget);
    expect(find.text(en.imageQualityLabel), findsOneWidget);
    expect(find.text(en.backgroundLabel), findsNothing);
    expect(find.text(en.keepMetadataLabel), findsOneWidget);

    // JPG cannot carry the PNG's transparency, so the backdrop becomes a real
    // question.
    await chooseTarget(tester, ImageFormat.jpg);

    expect(find.text(en.imageQualityLabel), findsOneWidget);
    expect(find.text(en.backgroundLabel), findsOneWidget);

    // PNG is lossless, so a quality number would be ignored.
    await chooseTarget(tester, ImageFormat.png);

    expect(find.text(en.imageQualityLabel), findsNothing);
    expect(find.text(en.backgroundLabel), findsNothing);
    expect(find.text(en.maxSideLabel), findsOneWidget);
  });

  testWidgets('the unsupported banner stays and picking is dead',
      (WidgetTester tester) async {
    await pumpScreen(
      tester,
      size: screenSizes['phone']!,
      isSupported: false,
    );

    expect(find.text(en.conversionUnsupportedError), findsOneWidget);
    expect(
      tester
          .widget<OutlinedButton>(
            find.widgetWithText(OutlinedButton, en.addPhotosLabel),
          )
          .onPressed,
      isNull,
    );
  });

  for (final MapEntry<String, Size> entry in screenSizes.entries) {
    testWidgets('the target grid uses ${expectedColumns[entry.key]} columns '
        'on ${entry.key}', (WidgetTester tester) async {
      await pumpScreen(tester, size: entry.value);
      await pickPhotos(tester);

      final GridView grid = tester.widget<GridView>(
        find.byType(GridView).first,
      );
      final SliverGridDelegateWithFixedCrossAxisCount delegate =
          grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;

      expect(delegate.crossAxisCount, expectedColumns[entry.key]);
    });
  }
}
