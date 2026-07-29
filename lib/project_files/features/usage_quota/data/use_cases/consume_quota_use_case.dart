import 'package:archonex_converter/core/constants/app_quota_limits.dart';
import 'package:archonex_converter/project_files/features/subscription/domain/subscription_repo.dart';
import 'package:archonex_converter/project_files/features/usage_quota/domain/usage_quota_repo.dart';

/// Charges a finished run against the free monthly count.
///
/// Called with the number of source files that actually made it through, so a
/// photo the engine choked on costs nothing. A subscriber's runs are not
/// counted at all — not merely ignored when read — so cancelling a
/// subscription starts the month from whatever was spent before it began.
///
/// An unmetered platform is not counted either, for the same reason and one
/// more: nothing should be written to the device for a number no screen will
/// ever read.
class ConsumeQuotaUseCase {
  const ConsumeQuotaUseCase({
    required UsageQuotaRepo quotaRepo,
    required SubscriptionRepo subscriptionRepo,
  })  : _quotaRepo = quotaRepo,
        _subscriptionRepo = subscriptionRepo;

  final UsageQuotaRepo _quotaRepo;
  final SubscriptionRepo _subscriptionRepo;

  Future<void> call(int fileCount) async {
    if (!AppQuotaLimits.isMetered ||
        _subscriptionRepo.statusListenable.value.isActive) {
      return;
    }

    await _quotaRepo.consume(fileCount);
  }
}
