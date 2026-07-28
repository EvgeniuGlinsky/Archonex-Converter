import 'package:equatable/equatable.dart';

/// The licence as this device remembers it between launches.
///
/// Kept so the app opens entitled rather than opening free and correcting
/// itself a network round trip later — and so a device with no connection at
/// all still knows what it bought.
final class LicenseRecord extends Equatable {
  const LicenseRecord({
    required this.key,
    required this.instanceId,
    required this.planId,
    required this.validatedAt,
    this.expiresAt,
  });

  final String key;

  /// This device's activation, as the service named it.
  final String instanceId;

  final String planId;

  /// When the service last confirmed this licence.
  ///
  /// The anchor for both timers: when to ask again, and how long silence is
  /// tolerated.
  final DateTime validatedAt;

  final DateTime? expiresAt;

  LicenseRecord confirmedAt(DateTime moment, {DateTime? expiresAt}) {
    return LicenseRecord(
      key: key,
      instanceId: instanceId,
      planId: planId,
      validatedAt: moment,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  @override
  List<Object?> get props =>
      <Object?>[key, instanceId, planId, validatedAt, expiresAt];
}
