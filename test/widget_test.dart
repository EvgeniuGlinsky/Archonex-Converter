import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:archonex/core/app/archonex_app.dart';
import 'package:archonex/core/constants/app_durations.dart';
import 'package:archonex/core/constants/app_strings.dart';

const Map<String, Size> _screenSizes = <String, Size>{
  'phone': Size(390, 844),
  'tablet': Size(834, 1112),
  'desktop': Size(1440, 900),
};

void main() {
  testWidgets('splash leads to language selection then a category page',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ArchonexApp());

    expect(find.text(AppStrings.appTagline), findsOneWidget);

    await tester.pump(AppDurations.splash);
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.languageTitle), findsOneWidget);

    await tester.tap(find.text(AppLanguageLabels.russian));
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.continueLabel));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.categoryTitle), findsOneWidget);

    await tester.tap(find.text(AppStrings.utilities));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text(AppStrings.utilities),
      ),
      findsOneWidget,
    );
  });

  testWidgets('file converters lists the catalogue and opens the converter',
      (WidgetTester tester) async {
    await _setSurfaceSize(tester, _screenSizes['phone']!);
    await _openCategories(tester);

    await tester.tap(find.text(AppStrings.fileConverters));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.fileConvertersTitle), findsOneWidget);
    expect(find.text(AppStrings.mediaConverter), findsOneWidget);
    expect(find.text(AppStrings.imageConverter), findsOneWidget);
    expect(find.text(AppStrings.documentConverter), findsOneWidget);
    // One badge per converter that is not built yet.
    expect(find.text(AppStrings.comingSoonBadge), findsNWidgets(2));

    await tester.tap(find.text(AppStrings.mediaConverter));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.mediaConverterTitle), findsOneWidget);
    expect(find.text(AppStrings.maxFileSizeNotice), findsOneWidget);
    // Nothing below the file card exists until a file has been picked.
    expect(find.text(AppStrings.convertToTitle), findsNothing);
    expect(find.text(AppStrings.qualityTitle), findsNothing);
  });

  testWidgets('convert stays disabled until a file is picked',
      (WidgetTester tester) async {
    await _setSurfaceSize(tester, _screenSizes['phone']!);
    await _openCategories(tester);

    await tester.tap(find.text(AppStrings.fileConverters));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.mediaConverter));
    await tester.pumpAndSettle();

    final Finder convertButton = find.widgetWithText(
      FilledButton,
      AppStrings.convertLabel,
    );

    expect(tester.widget<FilledButton>(convertButton).onPressed, isNull);
  });

  testWidgets('upcoming converters cannot be opened',
      (WidgetTester tester) async {
    await _setSurfaceSize(tester, _screenSizes['phone']!);
    await _openCategories(tester);

    await tester.tap(find.text(AppStrings.fileConverters));
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.imageConverter));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.fileConvertersTitle), findsOneWidget);
    expect(find.text(AppStrings.mediaConverterScreenSubtitle), findsNothing);
  });

  for (final MapEntry<String, Size> entry in _screenSizes.entries) {
    testWidgets('flow lays out without overflow on ${entry.key}',
        (WidgetTester tester) async {
      await _setSurfaceSize(tester, entry.value);

      await tester.pumpWidget(const ArchonexApp());
      await tester.pump(AppDurations.splash);
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.continueLabel));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.fileConverters), findsOneWidget);
      expect(find.text(AppStrings.newsApps), findsOneWidget);
    });
  }
}

/// Runs the app up to the category hub, where the product flows branch off.
Future<void> _openCategories(WidgetTester tester) async {
  await tester.pumpWidget(const ArchonexApp());
  await tester.pump(AppDurations.splash);
  await tester.pumpAndSettle();

  await tester.tap(find.text(AppStrings.continueLabel));
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
