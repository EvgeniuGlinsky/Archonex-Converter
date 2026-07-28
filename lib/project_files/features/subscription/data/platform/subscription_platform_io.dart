import 'dart:io';

import 'package:archonex_converter/project_files/features/subscription/data/free_only_subscription_repo.dart';
import 'package:archonex_converter/project_files/features/subscription/data/store/in_app_purchase_billing.dart';
import 'package:archonex_converter/project_files/features/subscription/data/store_subscription_repo.dart';
import 'package:archonex_converter/project_files/features/subscription/domain/models/purchase_channel.dart';
import 'package:archonex_converter/project_files/features/subscription/domain/subscription_repo.dart';

/// Every platform that has a file system, and so a converter worth paying for.
///
/// Two questions decide what comes back, and they are not the same question.
/// *Which platform* says whether a store exists here at all; *how this build was
/// distributed* says whether that store will talk to it. Only when both answers
/// are yes is there anything to sell.
SubscriptionRepo createSubscriptionRepo() {
  if (!_hasStore) {
    // Windows and Linux. Nothing to sell until a channel that needs no store
    // exists — the licence seam in `LicenseGateway` is where that will land.
    return FreeOnlySubscriptionRepo(channel: PurchaseChannel.unavailable);
  }

  if (!_isStoreBuild) {
    // An APK from GitHub Releases, or a local build. The store will not serve
    // billing to it, so the paywall points at the version that can be paid for
    // rather than offering a purchase that cannot complete.
    return FreeOnlySubscriptionRepo(channel: PurchaseChannel.storeBuildOnly);
  }

  return StoreSubscriptionRepo(billing: InAppPurchaseBilling());
}

/// Whether this platform has store billing that Flutter can reach.
///
/// Windows and Linux do not. Microsoft's store has its own commerce API, but no
/// Flutter plugin binds it, so from here it does not exist.
bool get _hasStore =>
    Platform.isAndroid || Platform.isIOS || Platform.isMacOS;

/// Whether this build was installed by a store.
///
/// It cannot be detected at runtime in any way worth trusting, so it is declared
/// at build time. The default is the safe answer: a build that says nothing about
/// itself is assumed not to have come from a store, which produces an honest
/// screen rather than a broken purchase.
///
/// ```
/// flutter build apk                                                  # direct
/// flutter build appbundle --dart-define=ARCHONEX_DISTRIBUTION=store  # for Play
/// ```
const bool _isStoreBuild =
    String.fromEnvironment('ARCHONEX_DISTRIBUTION', defaultValue: 'direct') ==
        'store';
