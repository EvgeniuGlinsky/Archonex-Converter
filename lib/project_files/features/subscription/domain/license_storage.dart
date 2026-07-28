import 'package:archonex_converter/project_files/features/subscription/domain/models/license_record.dart';

/// Contract for remembering the licence between launches.
///
/// The same split as `QuotaStorage`: every rule about clocks and expiry lives
/// in the repository, and this only holds what those rules produced. That is
/// what lets the rules be tested without a platform plugin.
abstract interface class LicenseStorage {
  Future<LicenseRecord?> read();

  Future<void> write(LicenseRecord record);

  /// Forgets the licence — after the service says it is dead, or after the
  /// grace period has run out.
  Future<void> clear();
}
