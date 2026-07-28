import 'dart:async';

import 'package:archonex_converter/core/constants/app_quota_limits.dart';
import 'package:archonex_converter/project_files/features/subscription/domain/subscription_repo.dart';
import 'package:archonex_converter/project_files/features/usage_quota/domain/models/conversion_allowance.dart';
import 'package:archonex_converter/project_files/features/usage_quota/domain/models/quota_usage.dart';
import 'package:archonex_converter/project_files/features/usage_quota/domain/usage_quota_repo.dart';

/// The one place the counter meets the subscription.
///
/// Converters ask what they are allowed to do, never who is paying. Keeping
/// the join here is what stops three screens from each growing their own
/// version of "unless subscribed".
class WatchConversionAllowanceUseCase {
  const WatchConversionAllowanceUseCase({
    required UsageQuotaRepo quotaRepo,
    required SubscriptionRepo subscriptionRepo,
  })  : _quotaRepo = quotaRepo,
        _subscriptionRepo = subscriptionRepo;

  final UsageQuotaRepo _quotaRepo;
  final SubscriptionRepo _subscriptionRepo;

  /// Emits the current allowance immediately, then again on every change to
  /// either input.
  Stream<ConversionAllowance> call() {
    late final StreamController<ConversionAllowance> controller;

    void emit() => controller.add(_allowance());

    controller = StreamController<ConversionAllowance>(
      onListen: () {
        _quotaRepo.usageListenable.addListener(emit);
        _subscriptionRepo.statusListenable.addListener(emit);
        emit();

        // A screen opening is the moment to notice that the month turned over
        // while the app sat in the background. The result arrives through the
        // listener above, so nothing here waits for it.
        unawaited(_quotaRepo.refresh());
      },
      onCancel: () {
        _quotaRepo.usageListenable.removeListener(emit);
        _subscriptionRepo.statusListenable.removeListener(emit);
      },
    );

    return controller.stream;
  }

  ConversionAllowance _allowance() {
    if (_subscriptionRepo.statusListenable.value.isActive) {
      return const ConversionAllowance.unlimited();
    }

    final QuotaUsage usage = _quotaRepo.usageListenable.value;

    return ConversionAllowance(
      usedFiles: usage.usedFiles,
      limit: AppQuotaLimits.freeFilesPerMonth,
      resetsAt: usage.period.resetsAt,
    );
  }
}
