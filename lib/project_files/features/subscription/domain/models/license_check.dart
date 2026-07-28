import 'package:equatable/equatable.dart';

/// What the licence service said about one key.
///
/// Separate from `PurchaseOutcome` on purpose: this is what the service
/// answered, and the outcome is what the user is told. One negative verdict can
/// mean different things to a redemption and to a restore, so the translation
/// belongs to whoever asked rather than to the answer.
enum LicenseVerdict {
  /// Paid up. The device is entitled.
  active,

  /// A real key whose subscription has lapsed, been refunded or cancelled.
  /// Worth saying out loud, because the user did once pay.
  inactive,

  /// Malformed, belonging to another product, or unknown to the service.
  unknown,

  /// The right key, but every activation slot it allows is already taken.
  activationLimitReached,
}

/// One answer from the licence service.
///
/// [instanceId] and [planId] are only filled in for [LicenseVerdict.active] —
/// a refusal has nothing to identify.
final class LicenseCheck extends Equatable {
  const LicenseCheck({
    required this.verdict,
    this.instanceId,
    this.planId,
    this.expiresAt,
  });

  const LicenseCheck.refused(this.verdict)
      : instanceId = null,
        planId = null,
        expiresAt = null;

  final LicenseVerdict verdict;

  /// Identifies this device's activation, and is what a later validation is
  /// checked against.
  final String? instanceId;

  final String? planId;

  /// End of the paid period the service currently knows about.
  ///
  /// Informational only. It is never used to decide entitlement locally: a
  /// monthly subscription's end date passes every month and renewing it is
  /// exactly what the service is asked about.
  final DateTime? expiresAt;

  bool get isActive => verdict == LicenseVerdict.active;

  @override
  List<Object?> get props => <Object?>[verdict, instanceId, planId, expiresAt];
}
