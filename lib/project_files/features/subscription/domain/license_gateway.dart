import 'package:archonex_converter/project_files/features/subscription/domain/models/checkout_offer.dart';
import 'package:archonex_converter/project_files/features/subscription/domain/models/license_check.dart';

/// The service could not be reached, or answered something unusable.
///
/// Deliberately distinct from a negative [LicenseCheck]: "the service says this
/// key is dead" and "nobody answered" have to lead to different behaviour, and
/// a single nullable return value cannot say which happened. Everything that
/// catches this treats it as *no information*, never as a refusal.
class LicenseServiceUnavailable implements Exception {
  const LicenseServiceUnavailable([this.detail]);

  final String? detail;

  @override
  String toString() => detail == null
      ? 'LicenseServiceUnavailable'
      : 'LicenseServiceUnavailable: $detail';
}

/// The one thing the app knows about the payment provider: an address that
/// answers three questions.
///
/// Narrow on purpose. Which provider is behind it — and whether licence keys
/// are its own feature or something the service mints itself — is invisible
/// from here, so switching providers costs one implementation and no changes
/// above this line.
abstract interface class LicenseGateway {
  /// What is for sale right now, priced and linked by the service.
  ///
  /// An empty list is a valid answer and means the shop is not open yet. The
  /// paywall says exactly that rather than inventing a price.
  Future<List<CheckoutOffer>> loadOffers();

  /// Binds [key] to this device and reports whether that worked.
  Future<LicenseCheck> activate({
    required String key,
    required String deviceName,
  });

  /// Re-asks about a key already bound to this device.
  Future<LicenseCheck> validate({
    required String key,
    required String instanceId,
  });
}
