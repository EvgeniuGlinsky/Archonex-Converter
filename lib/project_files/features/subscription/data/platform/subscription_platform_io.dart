import 'dart:io';

import 'package:archonex_converter/project_files/features/subscription/data/free_only_subscription_repo.dart';
import 'package:archonex_converter/project_files/features/subscription/data/store/in_app_purchase_billing.dart';
import 'package:archonex_converter/project_files/features/subscription/data/store_subscription_repo.dart';
import 'package:archonex_converter/project_files/features/subscription/domain/models/purchase_channel.dart';
import 'package:archonex_converter/project_files/features/subscription/domain/subscription_repo.dart';

/// Every platform that has a file system, and so a converter worth paying for.
///
/// Three questions decide what comes back, and they are not the same question.
/// *Whether anything is sold here at all* comes first; then *which platform*,
/// which says whether a store exists; then *how this build was distributed*,
/// which says whether that store will talk to it.
SubscriptionRepo createSubscriptionRepo() {
  if (Platform.isAndroid) {
    // Nothing is sold on Android, however the build was distributed. The
    // subscription is built and tested and shelved: `AppQuotaLimits.isMetered`
    // stopped counting conversions there, and a paywall with nothing to lift is
    // a paywall nothing should navigate to.
    //
    // This branch, rather than dropping `ARCHONEX_DISTRIBUTION=store` from the
    // release workflow: without it the Play bundle falls to `storeBuildOnly` and
    // tells a copy installed from Google Play to install itself from Google
    // Play. It is also what keeps `StoreSubscriptionRepo` from being built, and
    // so keeps Play Billing from being contacted at all — which is what makes
    // `docs/privacy.html` true when it says the app issues no network requests.
    //
    // Turning selling back on is this branch and the `isMetered` tier, in that
    // order. Nothing below it changed.
    return FreeOnlySubscriptionRepo(channel: PurchaseChannel.unavailable);
  }

  if (!_hasStore) {
    // Windows and Linux. Nothing to sell until a channel that needs no store
    // exists — the licence seam in `LicenseGateway` is where that will land.
    return FreeOnlySubscriptionRepo(channel: PurchaseChannel.unavailable);
  }

  if (!_isStoreBuild) {
    // A local build, or one handed out directly. The store will not serve
    // billing to it, so the paywall points at the version that can be paid for
    // rather than offering a purchase that cannot complete.
    return FreeOnlySubscriptionRepo(channel: PurchaseChannel.storeBuildOnly);
  }

  return StoreSubscriptionRepo(billing: InAppPurchaseBilling());
}

/// Whether this platform has store billing that Flutter can reach.
///
/// Windows and Linux do not. Microsoft's store has its own commerce API, but no
/// Flutter plugin binds it, so from here it does not exist. Android is absent
/// for a different reason — it has store billing and sells nothing with it, and
/// the branch above answers before this getter is ever read.
bool get _hasStore => Platform.isIOS || Platform.isMacOS;

/// Whether this build was installed by a store.
///
/// It cannot be detected at runtime in any way worth trusting, so it is declared
/// at build time. The default is the safe answer: a build that says nothing about
/// itself is assumed not to have come from a store, which produces an honest
/// screen rather than a broken purchase.
///
/// Read on iOS and macOS only. Android stopped reading it when it stopped selling
/// anything, so no Android build passes it and `release.yml` no longer defines it
/// — a define that changes nothing is worse than no define, because the next
/// person to read the build script believes it does something.
///
/// ```
/// flutter build ipa --dart-define=ARCHONEX_DISTRIBUTION=store  # for the App Store
/// ```
const bool _isStoreBuild =
    String.fromEnvironment('ARCHONEX_DISTRIBUTION', defaultValue: 'direct') ==
        'store';
