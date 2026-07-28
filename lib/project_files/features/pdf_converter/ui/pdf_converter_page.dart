import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:archonex_converter/project_files/features/pdf_converter/data/platform/pdf_converter_platform.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/data/use_cases/convert_pdf_use_case.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/data/use_cases/discard_converted_pdfs_use_case.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/data/use_cases/get_pdf_converter_availability_use_case.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/data/use_cases/pick_pdf_sources_use_case.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/data/use_cases/save_all_converted_pdfs_use_case.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/data/use_cases/save_converted_pdf_use_case.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/domain/pdf_converter_repo.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/domain/pdf_file_repo.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/ui/bloc/pdf_converter_bloc.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/ui/pdf_converter_view.dart';
import 'package:archonex_converter/project_files/features/subscription/domain/subscription_repo.dart';
import 'package:archonex_converter/project_files/features/usage_quota/data/use_cases/consume_quota_use_case.dart';
import 'package:archonex_converter/project_files/features/usage_quota/data/use_cases/watch_conversion_allowance_use_case.dart';
import 'package:archonex_converter/project_files/features/usage_quota/domain/usage_quota_repo.dart';

class PdfConverterPage extends StatelessWidget {
  const PdfConverterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final PdfConverterRepo converterRepo = createPdfConverterRepo();
    final PdfFileRepo fileRepo = createPdfFileRepo();

    // App-wide, unlike the two above: the count and the entitlement are shared
    // with every other screen.
    final UsageQuotaRepo quotaRepo = context.read<UsageQuotaRepo>();
    final SubscriptionRepo subscriptionRepo = context.read<SubscriptionRepo>();

    return BlocProvider<PdfConverterBloc>(
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
    );
  }
}
