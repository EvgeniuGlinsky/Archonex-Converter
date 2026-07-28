import 'package:equatable/equatable.dart';

/// Whether this device is currently entitled to unlimited conversions.
///
/// Per device and per platform, deliberately: the app has no accounts, so a
/// subscription bought in one store cannot be seen from another. That is a
/// product decision, not an oversight — see the README.
final class SubscriptionStatus extends Equatable {
  const SubscriptionStatus.free()
      : planId = null,
        expiresAt = null;

  const SubscriptionStatus.active({required this.planId, this.expiresAt});

  /// Which plan is entitling the device, `null` when none is.
  final String? planId;

  /// End of the paid period, when the channel reports one.
  final DateTime? expiresAt;

  bool get isActive => planId != null;

  @override
  List<Object?> get props => <Object?>[planId, expiresAt];
}
