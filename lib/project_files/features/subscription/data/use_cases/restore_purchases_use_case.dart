import 'package:archonex_converter/project_files/features/subscription/domain/models/purchase_outcome.dart';
import 'package:archonex_converter/project_files/features/subscription/domain/subscription_repo.dart';

/// Brings back a subscription already paid for on this account or key.
///
/// Not optional: the App Store rejects a paywall without it, and a reinstall
/// has no other way to get its entitlement back.
class RestorePurchasesUseCase {
  const RestorePurchasesUseCase(this._repo);

  final SubscriptionRepo _repo;

  Future<PurchaseOutcome> call() => _repo.restore();
}
