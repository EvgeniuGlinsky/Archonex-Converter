import 'package:shared_preferences/shared_preferences.dart';

import 'package:archonex_converter/project_files/features/subscription/domain/license_storage.dart';
import 'package:archonex_converter/project_files/features/subscription/domain/models/license_record.dart';

/// The licence, kept in the platform's own key-value store.
///
/// The same shape and the same reasoning as `PrefsQuotaStorage`:
/// `SharedPreferencesAsync` so no warm-up is needed before the first read, and
/// separate keys rather than one encoded blob so a stored licence stays
/// readable — and repairable — from the outside.
///
/// **Not a vault.** Preferences are plain files that the device's owner can
/// read and edit, so a determined user can forge or copy what is written here.
/// That is not what the storage is defending against: the licence is checked
/// against the service, and this only decides how the app behaves between those
/// checks. An offline app cannot do better without becoming an online one.
class PrefsLicenseStorage implements LicenseStorage {
  PrefsLicenseStorage([this._override]);

  static const String _keyKey = 'license.key';
  static const String _instanceKey = 'license.instance_id';
  static const String _planKey = 'license.plan_id';
  static const String _validatedAtKey = 'license.validated_at_millis';
  static const String _expiresAtKey = 'license.expires_at_millis';

  final SharedPreferencesAsync? _override;

  /// Built on first use for the same reason the quota's storage is: this object
  /// is created while the app root is still being built, and
  /// `SharedPreferencesAsync` throws where no platform implementation is
  /// registered. Failing on the first read is something the repository already
  /// knows how to live with; failing in the constructor would take the app down.
  late final SharedPreferencesAsync _preferences =
      _override ?? SharedPreferencesAsync();

  @override
  Future<LicenseRecord?> read() async {
    final String? key = await _preferences.getString(_keyKey);
    final String? instanceId = await _preferences.getString(_instanceKey);
    final String? planId = await _preferences.getString(_planKey);
    final int? validatedAtMillis = await _preferences.getInt(_validatedAtKey);

    // Any one of them missing means there is no licence worth trusting — a
    // first run, or a store someone has been editing.
    if (key == null ||
        instanceId == null ||
        planId == null ||
        validatedAtMillis == null) {
      return null;
    }

    final int? expiresAtMillis = await _preferences.getInt(_expiresAtKey);

    return LicenseRecord(
      key: key,
      instanceId: instanceId,
      planId: planId,
      validatedAt: DateTime.fromMillisecondsSinceEpoch(validatedAtMillis),
      expiresAt: expiresAtMillis == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(expiresAtMillis),
    );
  }

  @override
  Future<void> write(LicenseRecord record) async {
    await _preferences.setString(_keyKey, record.key);
    await _preferences.setString(_instanceKey, record.instanceId);
    await _preferences.setString(_planKey, record.planId);
    await _preferences.setInt(
      _validatedAtKey,
      record.validatedAt.millisecondsSinceEpoch,
    );

    final DateTime? expiresAt = record.expiresAt;
    if (expiresAt == null) {
      await _preferences.remove(_expiresAtKey);
    } else {
      await _preferences.setInt(
        _expiresAtKey,
        expiresAt.millisecondsSinceEpoch,
      );
    }
  }

  @override
  Future<void> clear() async {
    await _preferences.remove(_keyKey);
    await _preferences.remove(_instanceKey);
    await _preferences.remove(_planKey);
    await _preferences.remove(_validatedAtKey);
    await _preferences.remove(_expiresAtKey);
  }
}
