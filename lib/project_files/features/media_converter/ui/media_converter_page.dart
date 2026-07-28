import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:archonex_converter/project_files/features/media_converter/data/platform/media_converter_platform.dart';
import 'package:archonex_converter/project_files/features/media_converter/data/use_cases/convert_media_use_case.dart';
import 'package:archonex_converter/project_files/features/media_converter/data/use_cases/discard_converted_file_use_case.dart';
import 'package:archonex_converter/project_files/features/media_converter/data/use_cases/get_converter_availability_use_case.dart';
import 'package:archonex_converter/project_files/features/media_converter/data/use_cases/pick_source_file_use_case.dart';
import 'package:archonex_converter/project_files/features/media_converter/data/use_cases/save_converted_file_use_case.dart';
import 'package:archonex_converter/project_files/features/media_converter/domain/media_converter_repo.dart';
import 'package:archonex_converter/project_files/features/media_converter/domain/media_file_repo.dart';
import 'package:archonex_converter/project_files/features/media_converter/ui/bloc/media_converter_bloc.dart';
import 'package:archonex_converter/project_files/features/media_converter/ui/media_converter_view.dart';
import 'package:archonex_converter/project_files/features/subscription/domain/subscription_repo.dart';
import 'package:archonex_converter/project_files/features/usage_quota/data/use_cases/consume_quota_use_case.dart';
import 'package:archonex_converter/project_files/features/usage_quota/data/use_cases/watch_conversion_allowance_use_case.dart';
import 'package:archonex_converter/project_files/features/usage_quota/domain/usage_quota_repo.dart';

/// Wires the media converter dependencies. No UI lives here.
///
/// Which implementations arrive is decided by the platform boundary in
/// `data/platform/media_converter_platform.dart`, not by this file.
class MediaConverterPage extends StatelessWidget {
  const MediaConverterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final MediaConverterRepo converterRepo = createMediaConverterRepo();
    final MediaFileRepo mediaFileRepo = createMediaFileRepo();

    // App-wide, unlike the two above: the count and the entitlement are shared
    // with every other screen.
    final UsageQuotaRepo quotaRepo = context.read<UsageQuotaRepo>();
    final SubscriptionRepo subscriptionRepo = context.read<SubscriptionRepo>();

    return BlocProvider<MediaConverterBloc>(
      create: (_) => MediaConverterBloc(
        getConverterAvailability: GetConverterAvailabilityUseCase(converterRepo),
        pickSourceFile: PickSourceFileUseCase(mediaFileRepo),
        convertMedia: ConvertMediaUseCase(converterRepo),
        saveConvertedFile: SaveConvertedFileUseCase(mediaFileRepo),
        discardConvertedFile: DiscardConvertedFileUseCase(converterRepo),
        watchConversionAllowance: WatchConversionAllowanceUseCase(
          quotaRepo: quotaRepo,
          subscriptionRepo: subscriptionRepo,
        ),
        consumeQuota: ConsumeQuotaUseCase(
          quotaRepo: quotaRepo,
          subscriptionRepo: subscriptionRepo,
        ),
      )..add(const MediaConverterStarted()),
      child: const MediaConverterView(),
    );
  }
}
