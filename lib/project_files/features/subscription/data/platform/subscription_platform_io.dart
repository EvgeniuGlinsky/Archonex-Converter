import 'dart:io';

import 'package:archonex_converter/project_files/features/subscription/data/free_only_subscription_repo.dart';
import 'package:archonex_converter/project_files/features/subscription/data/license/http_license_gateway.dart';
import 'package:archonex_converter/project_files/features/subscription/data/license_subscription_repo.dart';
import 'package:archonex_converter/project_files/features/subscription/data/prefs_license_storage.dart';
import 'package:archonex_converter/project_files/features/subscription/data/url_checkout_launcher.dart';
import 'package:archonex_converter/project_files/features/subscription/domain/models/purchase_channel.dart';
import 'package:archonex_converter/project_files/features/subscription/domain/subscription_repo.dart';

/// Every platform that has a file system, and so a converter worth paying for.
SubscriptionRepo createSubscriptionRepo() {
  if (_isStoreBuild) {
    // Reserved for the day this binary is uploaded to a store. Until then no
    // store build exists, and pretending otherwise would put a purchase button
    // on screen that the store would refuse.
    return FreeOnlySubscriptionRepo(channel: PurchaseChannel.store);
  }

  return LicenseSubscriptionRepo(
    gateway: HttpLicenseGateway(),
    storage: PrefsLicenseStorage(),
    launcher: const UrlCheckoutLauncher(),
    deviceName: _deviceName,
  );
}

/// How this build reached the user — which is a different question from which
/// platform it is running on, and the one that decides how it may charge.
///
/// The same Android binary can be a Play upload or a file downloaded from GitHub
/// Releases, and only the first may use Play billing: `BillingClient` refuses to
/// serve an app that Play did not install and sign, so a purchase button in a
/// downloaded APK could never complete. Desktop has no store billing Flutter can
/// reach at all.
///
/// So the default is the licence key, on every platform, and store billing has
/// to be asked for explicitly at build time:
///
/// ```
/// flutter build appbundle --dart-define=ARCHONEX_DISTRIBUTION=store
/// ```
const bool _isStoreBuild =
    String.fromEnvironment('ARCHONEX_DISTRIBUTION', defaultValue: 'direct') ==
        'store';

/// What this device is called in the licence service's list of activations, so
/// a subscriber can tell their laptop from their phone when they run out of
/// slots.
///
/// The host name is what the user themselves named the machine, which beats a
/// generated identifier nobody can recognise. Read defensively: it is not
/// guaranteed to be readable on every platform, and a licence must not fail to
/// activate over a label.
String get _deviceName {
  final String platform = Platform.operatingSystem;

  try {
    return '${Platform.localHostname} ($platform)';
  } catch (_) {
    return platform;
  }
}
