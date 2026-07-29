import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:archonex_converter/core/app/archonex_app.dart';
import 'package:archonex_converter/core/constants/app_durations.dart';
import 'package:archonex_converter/l10n/app_localizations.dart';
import 'package:archonex_converter/project_files/features/converter_shared/ui/widgets/file_size_limit_notice.dart';

const Map<String, Size> _screenSizes = <String, Size>{
  'phone': Size(390, 844),
  'tablet': Size(834, 1112),
  'desktop': Size(1440, 900),
};

void main() {
  late AppLocalizations en;
  late AppLocalizations ru;

  setUpAll(() async {
    en = await AppLocalizations.delegate.load(const Locale('en'));
    ru = await AppLocalizations.delegate.load(const Locale('ru'));
  });

  testWidgets(
      'splash leads to language selection then straight to the converters '
      'in that language', (WidgetTester tester) async {
    await tester.pumpWidget(const ArchonexApp());

    expect(find.text(en.appTagline), findsOneWidget);

    await tester.pump(AppDurations.splash);
    await tester.pumpAndSettle();
    expect(find.text(en.languageTitle), findsOneWidget);

    await tester.tap(find.text(AppLanguageLabels.russian));
    await tester.pumpAndSettle();

    // The continue button itself is still in English: the picked language
    // only takes effect once it is confirmed.
    await tester.tap(find.text(en.continueLabel));
    await tester.pumpAndSettle();

    // Picking Russian actually switches the app's locale, so every screen
    // from here on renders in Russian.
    expect(find.text(ru.fileConvertersTitle), findsOneWidget);
  });

  testWidgets('file converters lists the catalogue and opens the converter',
      (WidgetTester tester) async {
    await _setSurfaceSize(tester, _screenSizes['phone']!);
    await _openFileConverters(tester, en);

    expect(find.text(en.fileConvertersTitle), findsOneWidget);
    expect(find.text(en.converterMediaTitle), findsOneWidget);
    expect(find.text(en.converterImageTitle), findsOneWidget);
    expect(find.text(en.converterPdfTitle), findsOneWidget);
    // Every converter in the catalogue is built, so nothing is badged.
    expect(find.text(en.comingSoonBadge), findsNothing);

    await tester.tap(find.text(en.converterMediaTitle));
    await tester.pumpAndSettle();

    expect(find.text(en.mediaConverterTitle), findsOneWidget);
    // Android, which `flutter_test` reports by default, bounds neither the source
    // nor the result, so no screen carries a limits line at all.
    expect(find.byType(FileSizeLimitNotice), findsNothing);
    // Nothing below the file card exists until a file has been picked.
    expect(find.text(en.convertToTitle), findsNothing);
    expect(find.text(en.qualityTitle), findsNothing);
  });

  testWidgets('convert stays disabled until a file is picked',
      (WidgetTester tester) async {
    await _setSurfaceSize(tester, _screenSizes['phone']!);
    await _openFileConverters(tester, en);

    await tester.tap(find.text(en.converterMediaTitle));
    await tester.pumpAndSettle();

    final Finder convertButton = find.widgetWithText(
      FilledButton,
      en.convertLabel,
    );

    expect(tester.widget<FilledButton>(convertButton).onPressed, isNull);
  });

  testWidgets('the image converter opens on an empty batch',
      (WidgetTester tester) async {
    await _setSurfaceSize(tester, _screenSizes['phone']!);
    await _openFileConverters(tester, en);

    await tester.tap(find.text(en.converterImageTitle));
    await tester.pumpAndSettle();

    expect(find.text(en.imageConverterTitle), findsOneWidget);
    expect(find.byType(FileSizeLimitNotice), findsNothing);
    // Nothing below the batch exists until photos have been added.
    expect(find.text(en.convertToTitle), findsNothing);
    expect(find.text(en.qualityTitle), findsNothing);
  });

  testWidgets('the pdf converter opens on an empty selection',
      (WidgetTester tester) async {
    await _setSurfaceSize(tester, _screenSizes['phone']!);
    await _openFileConverters(tester, en);

    await tester.tap(find.text(en.converterPdfTitle));
    await tester.pumpAndSettle();

    expect(find.text(en.pdfConverterTitle), findsOneWidget);
    expect(find.byType(FileSizeLimitNotice), findsNothing);
    // The direction is only known once something is picked, so there is no
    // target grid yet.
    expect(find.text(en.convertToTitle), findsNothing);
  });

  for (final MapEntry<String, Size> entry in _screenSizes.entries) {
    testWidgets('flow lays out without overflow on ${entry.key}',
        (WidgetTester tester) async {
      await _setSurfaceSize(tester, entry.value);

      await tester.pumpWidget(const ArchonexApp());
      await tester.pump(AppDurations.splash);
      await tester.pumpAndSettle();

      await tester.tap(find.text(en.continueLabel));
      await tester.pumpAndSettle();

      expect(find.text(en.fileConvertersTitle), findsOneWidget);
      expect(find.text(en.converterMediaTitle), findsOneWidget);
    });
  }
}

/// Runs the app up to the file converters hub, where the product flows
/// branch off.
Future<void> _openFileConverters(
  WidgetTester tester,
  AppLocalizations en,
) async {
  await tester.pumpWidget(const ArchonexApp());
  await tester.pump(AppDurations.splash);
  await tester.pumpAndSettle();

  await tester.tap(find.text(en.continueLabel));
  await tester.pumpAndSettle();
}

/// Renders the app at [size] logical pixels for the duration of the test.
Future<void> _setSurfaceSize(WidgetTester tester, Size size) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
}

/// Native labels of the languages, duplicated here so the test fails if the
/// user visible copy silently changes.
class AppLanguageLabels {
  const AppLanguageLabels._();

  static const String russian = 'Русский';
}
