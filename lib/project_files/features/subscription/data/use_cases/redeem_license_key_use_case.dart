import 'package:archonex_converter/project_files/features/subscription/domain/models/purchase_outcome.dart';
import 'package:archonex_converter/project_files/features/subscription/domain/subscription_repo.dart';

/// Unlocks the desktop build with a key bought on the web.
///
/// Trims before handing over: a key arrives by email and is pasted, and a
/// trailing newline is not a reason to tell someone their purchase is invalid.
class RedeemLicenseKeyUseCase {
  const RedeemLicenseKeyUseCase(this._repo);

  final SubscriptionRepo _repo;

  Future<PurchaseOutcome> call(String key) {
    final String trimmed = key.trim();

    return trimmed.isEmpty
        ? Future<PurchaseOutcome>.value(PurchaseOutcome.invalidLicenseKey)
        : _repo.redeemLicenseKey(trimmed);
  }
}
