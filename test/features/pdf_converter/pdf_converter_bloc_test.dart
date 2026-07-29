import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:archonex_converter/core/constants/app_quota_limits.dart';
import 'package:archonex_converter/project_files/features/converter_shared/domain/models/conversion_failure.dart';
import 'package:archonex_converter/project_files/features/converter_shared/domain/models/save_result.dart';
import 'package:archonex_converter/project_files/features/converter_shared/domain/models/source_file.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/data/use_cases/convert_pdf_use_case.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/data/use_cases/discard_converted_pdfs_use_case.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/data/use_cases/get_pdf_converter_availability_use_case.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/data/use_cases/pick_pdf_sources_use_case.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/data/use_cases/save_all_converted_pdfs_use_case.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/data/use_cases/save_converted_pdf_use_case.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/domain/models/pdf_conversion_settings.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/domain/models/pdf_format.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/domain/models/pdf_page_size.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/domain/models/pdf_target.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/ui/bloc/pdf_converter_bloc.dart';
import 'package:archonex_converter/project_files/features/usage_quota/data/use_cases/consume_quota_use_case.dart';
import 'package:archonex_converter/project_files/features/usage_quota/data/use_cases/watch_conversion_allowance_use_case.dart';

import '../subscription/fakes.dart';
import '../usage_quota/fakes.dart';
import 'fakes.dart';

void main() {
  late FakePdfFileRepo fileRepo;
  late FakePdfConverterRepo converterRepo;
  late FakeUsageQuotaRepo quotaRepo;
  late FakeSubscriptionRepo subscriptionRepo;
  late PdfConverterBloc bloc;

  /// Lets the bloc's event queue drain.
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  PdfConverterBloc buildBloc() => PdfConverterBloc(
        getConverterAvailability:
            GetPdfConverterAvailabilityUseCase(converterRepo),
        pickSources: PickPdfSourcesUseCase(fileRepo),
        convertPdf: ConvertPdfUseCase(converterRepo),
        saveConvertedPdf: SaveConvertedPdfUseCase(fileRepo),
        saveAllConvertedPdfs: SaveAllConvertedPdfsUseCase(fileRepo),
        discardConvertedPdfs: DiscardConvertedPdfsUseCase(converterRepo),
        // Real use cases over fake repositories: the join between the counter
        // and the subscription is exactly what these tests are about.
        watchConversionAllowance: WatchConversionAllowanceUseCase(
          quotaRepo: quotaRepo,
          subscriptionRepo: subscriptionRepo,
        ),
        consumeQuota: ConsumeQuotaUseCase(
          quotaRepo: quotaRepo,
          subscriptionRepo: subscriptionRepo,
        ),
      );

  setUp(() {
    // AppFileLimits reads the platform, so the ceilings have to be pinned.
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    fileRepo = FakePdfFileRepo();
    converterRepo = FakePdfConverterRepo();
    quotaRepo = FakeUsageQuotaRepo();
    subscriptionRepo = FakeSubscriptionRepo();
    bloc = buildBloc();
  });

  tearDown(() async {
    await bloc.close();
    debugDefaultTargetPlatformOverride = null;
  });

  /// Picks [files] and settles.
  Future<void> pick(List<SourceFile> files) async {
    fileRepo.pickResult = files;
    bloc.add(const PdfSourcesPickRequested());
    await settle();
  }

  Future<void> prepare({
    List<SourceFile>? files,
    PdfTarget target = PdfTarget.pdf,
  }) async {
    await pick(files ?? <SourceFile>[source('a.png'), source('b.png')]);
    bloc.add(PdfTargetSelected(target));
    await settle();
  }

  group('picking', () {
    test('a pick settles the direction and offers only what it can reach',
        () async {
      await pick(<SourceFile>[source('a.png')]);

      expect(bloc.state.sourceKind, PdfSourceKind.image);
      expect(bloc.state.availableTargets, const <PdfTarget>[PdfTarget.pdf]);
      expect(bloc.state.status, PdfConverterStatus.ready);
    });

    test('picking a PDF points the other way', () async {
      await pick(<SourceFile>[source('scan.pdf')]);

      expect(bloc.state.sourceKind, PdfSourceKind.pdf);
      expect(
        bloc.state.availableTargets,
        const <PdfTarget>[PdfTarget.png, PdfTarget.jpg],
      );
    });

    test('the same file twice is one entry', () async {
      await pick(<SourceFile>[source('a.png')]);
      await pick(<SourceFile>[source('a.png')]);

      expect(bloc.state.sources, hasLength(1));
    });

    test('a mixed pick fails and leaves the selection alone', () async {
      await pick(<SourceFile>[source('a.png')]);
      await pick(<SourceFile>[source('scan.pdf')]);

      expect(bloc.state.failure, isA<MixedSourceKindsFailure>());
      expect(bloc.state.sources, hasLength(1));
    });
  });

  group('editing the selection', () {
    test('removing the last file clears the target with it', () async {
      await prepare(files: <SourceFile>[source('a.png')]);
      expect(bloc.state.target, PdfTarget.pdf);

      bloc.add(const PdfSourceRemoved(0));
      await settle();

      expect(bloc.state.sources, isEmpty);
      expect(bloc.state.target, isNull);
      expect(bloc.state.status, PdfConverterStatus.idle);
    });

    test('clearing resets everything but the panel', () async {
      await prepare();
      bloc.add(const PdfAdvancedPanelToggled());
      await settle();

      bloc.add(const PdfSourcesCleared());
      await settle();

      expect(bloc.state.sources, isEmpty);
      expect(bloc.state.isAdvancedExpanded, isTrue);
    });
  });

  group('settings', () {
    test('a setting that the target cannot use is pruned away', () async {
      await prepare();

      bloc.add(const PdfRasterDpiChanged(600));
      await settle();

      // The target is PDF, where resolution means nothing.
      expect(
        bloc.state.settings.rasterDpi,
        PdfConversionSettings.defaultRasterDpi,
      );
    });

    test('a setting the target can use sticks', () async {
      await prepare();

      bloc.add(const PdfPageSizeChanged(PdfPageSize.a4));
      await settle();

      expect(bloc.state.settings.pageSize, PdfPageSize.a4);
    });

    test('switching direction drops settings tuned for the old one', () async {
      await prepare(files: <SourceFile>[source('scan.pdf')], target: PdfTarget.png);
      bloc.add(const PdfRasterDpiChanged(600));
      await settle();
      expect(bloc.state.settings.rasterDpi, 600);

      bloc.add(const PdfSourcesCleared());
      await settle();

      expect(
        bloc.state.settings.rasterDpi,
        PdfConversionSettings.defaultRasterDpi,
      );
    });
  });

  group('the free monthly count', () {
    test('a merge costs one file per source, not one per document', () async {
      await prepare(
        files: <SourceFile>[source('a.png'), source('b.png'), source('c.png')],
      );

      bloc.add(const PdfConversionRequested());
      await settle();
      converterRepo.lastJob!.produce('merged.pdf');
      await converterRepo.lastJob!.finish();
      await settle();

      expect(quotaRepo.consumed, <int>[3]);
    });

    test('one PDF split into many pages still costs one file', () async {
      await prepare(
        files: <SourceFile>[source('scan.pdf')],
        target: PdfTarget.png,
      );

      bloc.add(const PdfConversionRequested());
      await settle();

      final ControllablePdfConversionJob job = converterRepo.lastJob!;
      job.produce('scan_1.png');
      job.produce('scan_2.png');
      await job.finish();
      await settle();

      expect(quotaRepo.consumed, <int>[1]);
    });

    test('a failed run costs nothing', () async {
      await prepare();

      bloc.add(const PdfConversionRequested());
      await settle();
      await converterRepo.lastJob!.fail(const ConversionEngineFailure());
      await settle();

      expect(quotaRepo.consumed, isEmpty);
    });

    test('a selection larger than what is left blocks the button', () async {
      // Unlike the other two converters, this bloc is not started by `setUp`,
      // and nothing watches the count until it is.
      bloc.add(const PdfConverterStarted());
      await settle();

      quotaRepo.setUsed(AppQuotaLimits.freeFilesPerMonth - 1);
      await settle();
      await prepare();

      expect(bloc.state.filesInRun, 2);
      expect(bloc.state.canConvert, isFalse);
    });

    test('a subscriber is never counted', () async {
      subscriptionRepo.activate();
      await settle();
      await prepare();

      bloc.add(const PdfConversionRequested());
      await settle();
      converterRepo.lastJob!.produce('merged.pdf');
      await converterRepo.lastJob!.finish();
      await settle();

      expect(quotaRepo.consumed, isEmpty);
    });
  });

  group('converting', () {
    test('progress and results arrive as the run goes', () async {
      await prepare();

      bloc.add(const PdfConversionRequested());
      await settle();
      expect(bloc.state.isConverting, isTrue);

      final ControllablePdfConversionJob job = converterRepo.lastJob!;
      job.progress(done: 1, total: 2);
      await settle();
      expect(bloc.state.progress, 0.5);

      job.produce('a.pdf');
      await job.finish();
      await settle();

      expect(bloc.state.status, PdfConverterStatus.converted);
      expect(bloc.state.results, hasLength(1));
    });

    test('a rasterised run hands back one file per page', () async {
      await prepare(files: <SourceFile>[source('scan.pdf')], target: PdfTarget.png);

      bloc.add(const PdfConversionRequested());
      await settle();

      final ControllablePdfConversionJob job = converterRepo.lastJob!;
      job.progress(done: 0, total: 3);
      job.produce('scan_1.png');
      job.produce('scan_2.png');
      job.produce('scan_3.png');
      await job.finish();
      await settle();

      expect(bloc.state.results, hasLength(3));
    });

    test('a failure ends the whole run, unlike a batch of photos', () async {
      await prepare();

      bloc.add(const PdfConversionRequested());
      await settle();

      await converterRepo.lastJob!.fail(
        const UnsupportedCharactersFailure(sample: '你好'),
      );
      await settle();

      expect(bloc.state.failure, isA<UnsupportedCharactersFailure>());
      expect(bloc.state.results, isEmpty);
      expect(bloc.state.status, PdfConverterStatus.ready);
    });

    test('cancelling parks the screen back where it can act', () async {
      await prepare();

      bloc.add(const PdfConversionRequested());
      await settle();

      bloc.add(const PdfConversionCancelled());
      await settle();

      expect(converterRepo.lastJob!.wasCancelled, isTrue);
      expect(bloc.state.failure, isA<ConversionCancelledFailure>());
      expect(bloc.state.isConverting, isFalse);
    });
  });

  group('temporary files', () {
    test('a settings change throws the results away', () async {
      await prepare();
      bloc.add(const PdfConversionRequested());
      await settle();

      final ControllablePdfConversionJob job = converterRepo.lastJob!;
      job.produce('a.pdf');
      await job.finish();
      await settle();
      expect(bloc.state.results, hasLength(1));

      bloc.add(const PdfPageSizeChanged(PdfPageSize.a4));
      await settle();

      expect(bloc.state.results, isEmpty);
      expect(converterRepo.discarded, hasLength(1));
    });
  });

  group('saving', () {
    test('a saved location comes back on the state', () async {
      await prepare();
      bloc.add(const PdfConversionRequested());
      await settle();

      final ControllablePdfConversionJob job = converterRepo.lastJob!;
      job.produce('a.pdf');
      await job.finish();
      await settle();

      fileRepo.saveLocation = '/downloads/a.pdf';
      bloc.add(const ConvertedPdfSaveRequested(0));
      await settle();

      expect(bloc.state.status, PdfConverterStatus.saved);
      expect(bloc.state.savedLocation, '/downloads/a.pdf');
    });

    test('a cancelled dialog is not an error', () async {
      await prepare();
      bloc.add(const PdfConversionRequested());
      await settle();

      final ControllablePdfConversionJob job = converterRepo.lastJob!;
      job.produce('a.pdf');
      await job.finish();
      await settle();

      fileRepo.saveLocation = null;
      bloc.add(const ConvertedPdfSaveRequested(0));
      await settle();

      expect(bloc.state.status, PdfConverterStatus.converted);
      expect(bloc.state.failure, isNull);
    });

    test('saving everything reports how many landed', () async {
      await prepare(files: <SourceFile>[source('scan.pdf')], target: PdfTarget.png);
      bloc.add(const PdfConversionRequested());
      await settle();

      final ControllablePdfConversionJob job = converterRepo.lastJob!;
      job.produce('scan_1.png');
      job.produce('scan_2.png');
      await job.finish();
      await settle();

      fileRepo.saveAllResult = const SaveResult(
        outcome: SaveOutcome.savedToLocation,
        location: '/downloads',
        savedCount: 2,
      );
      bloc.add(const AllConvertedPdfsSaveRequested());
      await settle();

      expect(bloc.state.savedCount, 2);
      expect(fileRepo.lastSavedAll, hasLength(2));
    });
  });

  group('an unsupported platform', () {
    test('says so up front and refuses to pick', () async {
      converterRepo.isSupported = false;
      await bloc.close();
      bloc = buildBloc();

      bloc.add(const PdfConverterStarted());
      await settle();

      expect(bloc.state.isSupported, isFalse);
      expect(bloc.state.canPick, isFalse);
      expect(bloc.state.canConvert, isFalse);
    });
  });
}
