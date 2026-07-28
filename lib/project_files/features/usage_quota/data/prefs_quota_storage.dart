import 'package:shared_preferences/shared_preferences.dart';

import 'package:archonex_converter/project_files/features/usage_quota/domain/models/quota_period.dart';
import 'package:archonex_converter/project_files/features/usage_quota/domain/models/quota_record.dart';
import 'package:archonex_converter/project_files/features/usage_quota/domain/models/quota_usage.dart';
import 'package:archonex_converter/project_files/features/usage_quota/domain/quota_storage.dart';

/// The counter, kept in the platform's own key-value store.
///
/// `SharedPreferencesAsync` rather than the legacy `SharedPreferences`: it
/// needs no warm-up before the first read, which is what lets this be built
/// synchronously alongside the other app-wide repositories, and the legacy API
/// is on its way to deprecation.
///
/// Three integers rather than one encoded blob, so a stored value stays
/// readable — and repairable — from the outside.
class PrefsQuotaStorage implements QuotaStorage {
  PrefsQuotaStorage([this._override]);

  static const String _periodKey = 'quota.period_key';
  static const String _usedFilesKey = 'quota.used_files';
  static const String _lastSeenKey = 'quota.last_seen_millis';

  final SharedPreferencesAsync? _override;

  /// Built on first use, not in the constructor: `SharedPreferencesAsync`
  /// throws where no platform implementation is registered, and this object is
  /// created while the app root is still being built. Failing there would take
  /// the whole app down over a counter; failing on the first read is something
  /// `UsageQuotaRepoImpl` already knows how to live with.
  late final SharedPreferencesAsync _preferences =
      _override ?? SharedPreferencesAsync();

  @override
  Future<QuotaRecord?> read() async {
    final int? periodKey = await _preferences.getInt(_periodKey);
    final int? lastSeenMillis = await _preferences.getInt(_lastSeenKey);

    // Either one missing means there is nothing trustworthy to roll over from,
    // which is a first run — or a store someone has been editing.
    if (periodKey == null || lastSeenMillis == null) {
      return null;
    }

    return QuotaRecord(
      usage: QuotaUsage(
        usedFiles: await _preferences.getInt(_usedFilesKey) ?? 0,
        period: QuotaPeriod.fromKey(periodKey),
      ),
      lastSeen: DateTime.fromMillisecondsSinceEpoch(lastSeenMillis),
    );
  }

  @override
  Future<void> write(QuotaRecord record) async {
    await _preferences.setInt(_periodKey, record.usage.period.key);
    await _preferences.setInt(_usedFilesKey, record.usage.usedFiles);
    await _preferences.setInt(
      _lastSeenKey,
      record.lastSeen.millisecondsSinceEpoch,
    );
  }
}
