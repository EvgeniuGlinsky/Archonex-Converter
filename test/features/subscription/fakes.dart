import 'package:flutter/foundation.dart';

import 'package:archonex_converter/project_files/features/subscription/domain/models/purchase_channel.dart';
import 'package:archonex_converter/project_files/features/subscription/domain/models/purchase_outcome.dart';
import 'package:archonex_converter/project_files/features/subscription/domain/models/subscription_plan.dart';
import 'package:archonex_converter/project_files/features/subscription/domain/models/subscription_status.dart';
import 'package:archonex_converter/project_files/features/subscription/domain/subscription_repo.dart';

/// Subscription state driven entirely by the test.
///
/// A successful attempt flips the entitlement, the way a real store would:
/// nothing in the app sets the status from a return value, so a fake that only
/// returned [PurchaseOutcome.succeeded] would never prove the screen reacts.
class FakeSubscriptionRepo implements SubscriptionRepo {
  FakeSubscriptionRepo({
    this.channel = PurchaseChannel.store,
    this.plans = const <SubscriptionPlan>[],
    this.outcome = PurchaseOutcome.succeeded,
    bool isActive = false,
  }) : _status = ValueNotifier<SubscriptionStatus>(
          isActive
              ? const SubscriptionStatus.active(planId: activePlanId)
              : const SubscriptionStatus.free(),
        );

  static const String activePlanId = 'test.plan.monthly';

  @override
  PurchaseChannel channel;

  List<SubscriptionPlan> plans;

  /// What the next purchase, redemption or restore returns.
  PurchaseOutcome outcome;

  final ValueNotifier<SubscriptionStatus> _status;

  int refreshCallCount = 0;
  int restoreCallCount = 0;
  SubscriptionPlan? lastPurchasedPlan;
  String? lastRedeemedKey;

  @override
  ValueListenable<SubscriptionStatus> get statusListenable => _status;

  @override
  Future<void> refresh() async => refreshCallCount++;

  @override
  Future<List<SubscriptionPlan>> loadPlans() async => plans;

  @override
  Future<PurchaseOutcome> purchase(SubscriptionPlan plan) async {
    lastPurchasedPlan = plan;

    return _settle();
  }

  @override
  Future<PurchaseOutcome> redeemLicenseKey(String key) async {
    lastRedeemedKey = key;

    return _settle();
  }

  @override
  Future<PurchaseOutcome> restore() async {
    restoreCallCount++;

    return _settle();
  }

  /// Turns the entitlement on without a purchase, for setting a test up.
  void activate() =>
      _status.value = const SubscriptionStatus.active(planId: activePlanId);

  PurchaseOutcome _settle() {
    if (outcome == PurchaseOutcome.succeeded) {
      activate();
    }

    return outcome;
  }
}
