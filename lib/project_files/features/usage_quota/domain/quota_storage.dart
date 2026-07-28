import 'package:archonex_converter/project_files/features/usage_quota/domain/models/quota_record.dart';

/// Where the counter is kept between runs.
///
/// Narrow on purpose. The repository holds every rule about periods and
/// clocks; this only reads and writes what those rules produced, which is what
/// lets the rules be tested without a platform plugin — and what makes moving
/// the record somewhere sturdier later a one file change.
abstract interface class QuotaStorage {
  /// `null` when nothing was ever written, i.e. a first run.
  Future<QuotaRecord?> read();

  Future<void> write(QuotaRecord record);
}
