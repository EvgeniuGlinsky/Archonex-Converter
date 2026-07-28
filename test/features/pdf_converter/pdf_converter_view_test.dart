import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:archonex_converter/core/constants/app_file_limits.dart';
import 'package:archonex_converter/core/theme/app_theme.dart';
import 'package:archonex_converter/l10n/app_localizations.dart';
import 'package:archonex_converter/project_files/features/converter_shared/domain/models/source_file.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/data/use_cases/convert_pdf_use_case.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/data/use_cases/discard_converted_pdfs_use_case.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/data/use_cases/get_pdf_converter_availability_use_case.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/data/use_cases/pick_pdf_sources_use_case.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/data/use_cases/save_all_converted_pdfs_use_case.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/data/use_cases/save_converted_pdf_use_case.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/ui/bloc/pdf_converter_bloc.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/ui/pdf_converter_view.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/ui/widgets/pdf_converter_actions.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/ui/widgets/pdf_target_grid.dart';
import 'package:archonex_converter/project_files/features/usage_quota/data/use_cases/consume_quota_use_case.dart';
import 'package:archonex_converter/project_files/features/usage_quota/data/use_cases/watch_conversion_allowance_use_case.dart';

import '../subscription/fakes.dart';
import '../usage_quota/fakes.dart';
import 'fakes.dart';

/// Tall enough that the whole body is built: it is a `ListView`, so anything
/// below the fold would simply not exist to find.
const Size _tallScreen = Size(1440, 2600);

void main() {
  late AppLocalizations en;
  late FakePdfFileRepo fileRepo;
  late FakePdfConverterRepo converterRepo;
  late FakeUsageQuotaRepo quotaRepo;
  late FakeSubscriptionRepo subscriptionRepo;

  setUpAll(() async {
    en = await AppLocalizations.delegate.load(const Locale('en'));
  });

  setUp(() {
    // No platform override here, unlike the bloc tests: `testWidgets` verifies
    // the foundation debug variables are unset before `tearDown` gets to run.
    // Every expectation below reads its numbers back out of `AppFileLimits`,
    // so it holds whatever platform the test host reports.
    fileRepo = FakePdfFileRepo();
    converterRepo = FakePdfConverterRepo();
    quotaRepo = FakeUsageQuotaRepo();
    // Subscribed on purpose: the quota banner would add a row to every screen
    // below, and none of these tests are about it. Its own coverage lives in
    // the image converter's view test.
    subscriptionRepo = FakeSubscriptionRepo(isActive: true);
  });

  /// The bloc is built inside `BlocProvider.create` on purpose: created in
  /// `setUp` it would live in another async zone, and events added from the
  /// test would never be delivered.
  Future<void> pumpScreen(
    WidgetTester tester, {
    Size size = _tallScreen,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<PdfConverterBloc>(
          create: (_) => PdfConverterBloc(
            getConverterAvailability:
                GetPdfConverterAvailabilityUseCase(converterRepo),
            pickSources: PickPdfSourcesUseCase(fileRepo),
            convertPdf: ConvertPdfUseCase(converterRepo),
            saveConvertedPdf: SaveConvertedPdfUseCase(fileRepo),
            saveAllConvertedPdfs: SaveAllConvertedPdfsUseCase(fileRepo),
            discardConvertedPdfs: DiscardConvertedPdfsUseCase(converterRepo),
            watchConversionAllowance: WatchConversionAllowanceUseCase(
              quotaRepo: quotaRepo,
              subscriptionRepo: subscriptionRepo,
            ),
            consumeQuota: ConsumeQuotaUseCase(
              quotaRepo: quotaRepo,
              subscriptionRepo: subscriptionRepo,
            ),
          )..add(const PdfConverterStarted()),
          child: const PdfConverterView(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pick(WidgetTester tester, List<SourceFile> files) async {
    fileRepo.pickResult = files;
    await tester.tap(find.text(en.addFilesLabel));
    await tester.pumpAndSettle();
  }

  /// Scoped to the target grid: a picked file shows its own format badge, so a
  /// bare `find.text('PNG')` would match the source row too.
  Finder targetTile(String label) => find.descendant(
        of: find.byType(PdfTargetGrid),
        matching: find.text(label),
      );

  testWidgets('an empty screen offers nothing but the limits and a picker',
      (WidgetTester tester) async {
    await pumpScreen(tester);

    expect(find.text(en.pdfConverterTitle), findsOneWidget);
    expect(
      find.text(
        en.pdfSourcesNotice(
          AppFileLimits.maxBatchFiles,
          AppFileLimits.maxUploadLabel,
        ),
      ),
      findsOneWidget,
    );
    expect(find.text(en.addFilesLabel), findsOneWidget);

    // The direction is unknown until something is picked, so no targets.
    expect(find.text(en.convertToTitle), findsNothing);
  });

  testWidgets('picking pictures reveals the one target they can reach',
      (WidgetTester tester) async {
    await pumpScreen(tester);
    await pick(tester, <SourceFile>[source('a.png'), source('b.png')]);

    expect(find.text(en.convertToTitle), findsOneWidget);
    expect(targetTile('PDF'), findsOneWidget);
    // Pictures cannot become pictures here — that is the image converter.
    expect(targetTile('PNG'), findsNothing);
  });

  testWidgets('picking a PDF reveals the other direction instead',
      (WidgetTester tester) async {
    await pumpScreen(tester);
    await pick(tester, <SourceFile>[source('scan.pdf')]);

    expect(targetTile('PNG'), findsOneWidget);
    expect(targetTile('JPG'), findsOneWidget);
    expect(targetTile('PDF'), findsNothing);
  });

  testWidgets('the advanced panel offers only what the direction can use',
      (WidgetTester tester) async {
    await pumpScreen(tester);
    await pick(tester, <SourceFile>[source('a.png')]);

    await tester.tap(targetTile('PDF'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(en.advancedTitle));
    await tester.pumpAndSettle();

    // Writing a PDF: geometry applies, resolution does not.
    expect(find.text(en.pageSizeLabel), findsOneWidget);
    expect(find.text(en.marginLabel), findsOneWidget);
    expect(find.text(en.resolutionDpiLabel), findsNothing);
  });

  testWidgets('the other direction swaps the panel over',
      (WidgetTester tester) async {
    await pumpScreen(tester);
    await pick(tester, <SourceFile>[source('scan.pdf')]);

    await tester.tap(targetTile('JPG'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(en.advancedTitle));
    await tester.pumpAndSettle();

    expect(find.text(en.resolutionDpiLabel), findsOneWidget);
    expect(find.text(en.imageQualityLabel), findsOneWidget);
    expect(find.text(en.pageSizeLabel), findsNothing);
  });

  testWidgets('convert stays disabled until a target is chosen',
      (WidgetTester tester) async {
    await pumpScreen(tester);

    // Scoped to the actions slot: the empty state has a tonal "Add files"
    // button, which is also a FilledButton and is enabled from the start.
    final Finder button = find.descendant(
      of: find.byType(PdfConverterActions),
      matching: find.byType(FilledButton),
    );

    expect(tester.widget<FilledButton>(button).onPressed, isNull);

    await pick(tester, <SourceFile>[source('a.png')]);
    expect(tester.widget<FilledButton>(button).onPressed, isNull);

    await tester.tap(targetTile('PDF'));
    await tester.pumpAndSettle();

    expect(tester.widget<FilledButton>(button).onPressed, isNotNull);
  });

  testWidgets('an unsupported platform says so before anything is picked',
      (WidgetTester tester) async {
    converterRepo.isSupported = false;

    await pumpScreen(tester);

    expect(find.text(en.conversionUnsupportedError), findsOneWidget);
  });
}
