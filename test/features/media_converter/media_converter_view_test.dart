import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:archonex/core/theme/app_theme.dart';
import 'package:archonex/l10n/app_localizations.dart';
import 'package:archonex/project_files/features/converter_shared/domain/models/source_file.dart';
import 'package:archonex/project_files/features/media_converter/data/use_cases/convert_media_use_case.dart';
import 'package:archonex/project_files/features/media_converter/data/use_cases/discard_converted_file_use_case.dart';
import 'package:archonex/project_files/features/media_converter/data/use_cases/get_converter_availability_use_case.dart';
import 'package:archonex/project_files/features/media_converter/data/use_cases/pick_source_file_use_case.dart';
import 'package:archonex/project_files/features/media_converter/data/use_cases/save_converted_file_use_case.dart';
import 'package:archonex/project_files/features/media_converter/domain/models/media_format.dart';
import 'package:archonex/project_files/features/media_converter/ui/bloc/media_converter_bloc.dart';
import 'package:archonex/project_files/features/media_converter/ui/media_converter_view.dart';

import 'fakes.dart';

/// The converter cannot be driven through `ArchonexApp`: picking a file needs
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

  const SourceFile videoSource = SourceFile(
    name: 'clip.mov',
    sizeInBytes: 5 * 1024 * 1024,
    path: '/tmp/clip.mov',
  );

  late MediaConverterBloc bloc;
  late AppLocalizations en;

  setUpAll(() async {
    en = await AppLocalizations.delegate.load(const Locale('en'));
  });

  MediaConverterBloc createBloc({required bool isSupported}) {
    final FakeMediaFileRepo fileRepo = FakeMediaFileRepo(
      pickResult: videoSource,
    );
    final FakeMediaConverterRepo converterRepo = FakeMediaConverterRepo(
      isSupported: isSupported,
    );

    return MediaConverterBloc(
      getConverterAvailability: GetConverterAvailabilityUseCase(converterRepo),
      pickSourceFile: PickSourceFileUseCase(fileRepo),
      convertMedia: ConvertMediaUseCase(converterRepo),
      saveConvertedFile: SaveConvertedFileUseCase(fileRepo),
      discardConvertedFile: DiscardConvertedFileUseCase(converterRepo),
    )..add(const MediaConverterStarted());
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
        home: BlocProvider<MediaConverterBloc>(
          create: (_) => bloc = createBloc(isSupported: isSupported),
          child: const MediaConverterView(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pickFile(WidgetTester tester) async {
    bloc.add(const SourceFilePickRequested());
    await tester.pumpAndSettle();
  }

  Future<void> chooseTarget(WidgetTester tester, MediaFormat target) async {
    bloc.add(TargetFormatSelected(target));
    await tester.pumpAndSettle();
  }

  Future<void> openAdvanced(WidgetTester tester) async {
    bloc.add(const AdvancedPanelToggled());
    await tester.pumpAndSettle();
  }

  testWidgets('shows nothing beyond the file card before a pick',
      (WidgetTester tester) async {
    await pumpScreen(tester, size: screenSizes['phone']!);

    expect(find.text(en.chooseFileLabel), findsOneWidget);
    expect(find.text(en.convertToTitle), findsNothing);
    expect(find.text(en.qualityTitle), findsNothing);
    expect(find.text(en.advancedTitle), findsNothing);
  });

  testWidgets('a pick reveals the targets, a target reveals the settings',
      (WidgetTester tester) async {
    await pumpScreen(tester, size: tallScreen);
    await pickFile(tester);

    expect(find.text(en.convertToTitle), findsOneWidget);
    expect(find.text(en.videoTargetsTitle), findsOneWidget);
    expect(find.text(en.audioTargetsTitle), findsOneWidget);
    // Quality only makes sense once there is something to produce.
    expect(find.text(en.qualityTitle), findsNothing);

    await chooseTarget(tester, MediaFormat.mp4);

    expect(find.text(en.qualityTitle), findsOneWidget);
    expect(find.text(en.advancedTitle), findsOneWidget);
  });

  testWidgets('convert enables only once a target is chosen',
      (WidgetTester tester) async {
    await pumpScreen(tester, size: screenSizes['phone']!);
    await pickFile(tester);

    final Finder untargeted = find.widgetWithText(
      FilledButton,
      en.convertLabel,
    );
    expect(tester.widget<FilledButton>(untargeted).onPressed, isNull);

    await chooseTarget(tester, MediaFormat.mp4);

    final Finder targeted = find.widgetWithText(
      FilledButton,
      en.convertToLabel(MediaFormat.mp4.label),
    );
    expect(tester.widget<FilledButton>(targeted).onPressed, isNotNull);
  });

  testWidgets('the advanced panel offers only what the target can use',
      (WidgetTester tester) async {
    await pumpScreen(tester, size: tallScreen);
    await pickFile(tester);
    await chooseTarget(tester, MediaFormat.mp4);
    await openAdvanced(tester);

    expect(find.text(en.resolutionLabel), findsOneWidget);
    expect(find.text(en.frameRateLabel), findsOneWidget);
    expect(find.text(en.videoQualityLabel), findsOneWidget);
    expect(find.text(en.keepAudioLabel), findsOneWidget);

    // MP3 has no picture to size, rate or grade.
    await chooseTarget(tester, MediaFormat.mp3);

    expect(find.text(en.resolutionLabel), findsNothing);
    expect(find.text(en.frameRateLabel), findsNothing);
    expect(find.text(en.videoQualityLabel), findsNothing);
    expect(find.text(en.keepAudioLabel), findsNothing);
    expect(find.text(en.audioBitrateLabel), findsOneWidget);

    // A GIF keeps its size and rate but carries no sound at all.
    await chooseTarget(tester, MediaFormat.gif);

    expect(find.text(en.resolutionLabel), findsOneWidget);
    expect(find.text(en.frameRateLabel), findsOneWidget);
    expect(find.text(en.videoQualityLabel), findsNothing);
    expect(find.text(en.audioBitrateLabel), findsNothing);

    // WAV is lossless, so a bitrate would be ignored.
    await chooseTarget(tester, MediaFormat.wav);

    expect(find.text(en.audioBitrateLabel), findsNothing);
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
            find.widgetWithText(OutlinedButton, en.chooseFileLabel),
          )
          .onPressed,
      isNull,
    );
  });

  for (final MapEntry<String, Size> entry in screenSizes.entries) {
    testWidgets('the target grid uses ${expectedColumns[entry.key]} columns '
        'on ${entry.key}', (WidgetTester tester) async {
      await pumpScreen(tester, size: entry.value);
      await pickFile(tester);

      final GridView grid = tester.widget<GridView>(
        find.byType(GridView).first,
      );
      final SliverGridDelegateWithFixedCrossAxisCount delegate =
          grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;

      expect(delegate.crossAxisCount, expectedColumns[entry.key]);
    });
  }
}
