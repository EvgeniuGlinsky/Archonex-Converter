import 'package:flutter/foundation.dart';

import 'package:archonex_converter/project_files/features/subscription/domain/models/purchase_channel.dart';
import 'package:archonex_converter/project_files/features/subscription/domain/models/purchase_outcome.dart';
import 'package:archonex_converter/project_files/features/subscription/domain/models/subscription_plan.dart';
import 'package:archonex_converter/project_files/features/subscription/domain/models/subscription_status.dart';

/// Contract for the paid tier.
///
/// One interface for both payment routes, because everything above this layer
/// asks the same two questions — is this device entitled, and how would it
/// become entitled. Which of [purchase] and [redeemLicenseKey] is reachable is
/// answered by [channel]; the other one returns
/// [PurchaseOutcome.unavailable].
abstract interface class SubscriptionRepo {
  /// What this build can offer. Fixed for the lifetime of the process.
  PurchaseChannel get channel;

  ValueListenable<SubscriptionStatus> get statusListenable;

  /// Re-reads the entitlement from wherever it lives.
  Future<void> refresh();

  /// Plans to display, priced by the store. Empty when there is nothing to
  /// sell — which is also what the paywall says out loud rather than inventing
  /// a price of its own.
  Future<List<SubscriptionPlan>> loadPlans();

  /// Store route: opens the platform's purchase sheet.
  Future<PurchaseOutcome> purchase(SubscriptionPlan plan);

  /// Licence key route: validates a key bought on the web and binds it to this
  /// device.
  Future<PurchaseOutcome> redeemLicenseKey(String key);

  /// Brings back a purchase already made on this account or key. Required by
  /// the App Store, and the only way a reinstall gets its subscription back.
  Future<PurchaseOutcome> restore();
}
