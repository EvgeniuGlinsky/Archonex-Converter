import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:archonex_converter/core/constants/app_store_policy.dart';
import 'package:archonex_converter/project_files/features/subscription/domain/models/plan_catalog.dart';
import 'package:archonex_converter/project_files/features/subscription/domain/models/purchase_channel.dart';
import 'package:archonex_converter/project_files/features/subscription/domain/models/purchase_outcome.dart';
import 'package:archonex_converter/project_files/features/subscription/domain/models/subscription_plan.dart';
import 'package:archonex_converter/project_files/features/subscription/domain/models/subscription_status.dart';
import 'package:archonex_converter/project_files/features/subscription/domain/store_billing.dart';
import 'package:archonex_converter/project_files/features/subscription/domain/store_products.dart';
import 'package:archonex_converter/project_files/features/subscription/domain/subscription_repo.dart';

/// The paid tier sold through the platform's own store.
///
/// **Why this is the route that ships.** The store is the merchant of record: it
/// takes the payment, remits the tax in every country it sells in, and owns the
/// entitlement. That is the whole reason there is no server behind this file —
/// nothing here has to remember who paid, because the store already does.
///
/// **Only in a build the store installed.** Google Play refuses to serve
/// `BillingClient` to an app it did not install and sign, so this repository is
/// chosen only for a store build; see `subscription_platform_io.dart`. In a copy
/// downloaded from GitHub it would show a purchase button that could never
/// complete.
///
/// **Everything arrives out of band.** The store reports through one stream
/// rather than by returning from the call that caused it, and it reports things
/// the app never asked for: a renewal overnight, a purchase made on another
/// device, a refund. So the entitlement is only ever set from that stream, and
/// the value returned by [purchase] says how the attempt went and nothing more.
///
/// **What this does not do.** The receipt is not verified against a server,
/// because there is no server. A rooted device running a patched store client can
/// claim a purchase that never happened. Closing that means running conversions
/// somewhere other than the user's machine, which is the opposite of what this
/// app is.
class StoreSubscriptionRepo implements SubscriptionRepo {
  StoreSubscriptionRepo({required StoreBilling billing}) : _billing = billing {
    // Subscribed before anything is asked of the store, because a restore or a
    // renewal can arrive the instant the stream is listened to — and an
    // entitlement reported into a stream nobody is reading is an entitlement
    // lost.
    _purchases = _billing.purchases.listen(_onPurchases, onError: (Object _) {});
  }

  final StoreBilling _billing;

  late final StreamSubscription<List<StorePurchase>> _purchases;

  final ValueNotifier<SubscriptionStatus> _status =
      ValueNotifier<SubscriptionStatus>(const SubscriptionStatus.free());

  /// What the store last said it sells. Held because a purchase may only be
  /// started for a product the store itself handed over.
  List<StoreProduct> _products = const <StoreProduct>[];

  /// Set by the stream whenever an entitling purchase arrives, and read after a
  /// restore to tell "nothing came back" from "not yet".
  bool _sawEntitlement = false;

  /// The purchase currently being waited on, if any.
  Completer<PurchaseOutcome>? _pending;

  @override
  PurchaseChannel get channel => PurchaseChannel.store;

  @override
  ValueListenable<SubscriptionStatus> get statusListenable => _status;

  /// Re-asks the store what this account owns.
  ///
  /// This is the only way a subscription cancelled outside the app is ever
  /// noticed, so it cannot be skipped — but a store that cannot be reached is not
  /// evidence of anything, and leaves the entitlement exactly as it was.
  @override
  Future<void> refresh() async {
    _sawEntitlement = false;

    try {
      if (!await _billing.isAvailable()) {
        return;
      }

      await _billing.restore();
    } catch (_) {
      return;
    }

    await Future<void>.delayed(AppStorePolicy.restoreWindow);

    if (!_sawEntitlement) {
      _status.value = const SubscriptionStatus.free();
    }
  }

  @override
  Future<PlanCatalog> loadPlans() async {
    try {
      if (!await _billing.isAvailable()) {
        return const PlanCatalog.unavailable(CatalogProblem.storeUnreachable);
      }

      _products = await _billing.queryProducts(StoreProducts.subscriptionIds);
    } catch (_) {
      // Nothing shown and nothing invented — but reported as a store that would
      // not answer rather than a shop with nothing in it. The two look identical
      // from here and call for opposite things from the user, so the paywall is
      // told which one this was.
      return const PlanCatalog.unavailable(CatalogProblem.storeUnreachable);
    }

    // One plan per product id, keeping the first the store named. A store may
    // answer with the same product more than once — Play lists a subscription's
    // base plan and every promotional offer on it separately, all under one id —
    // and a paywall that drew each of them would offer the same subscription
    // twice at two prices, only one of which `purchase` would then start.
    final Set<String> seen = <String>{};
    final List<SubscriptionPlan> plans = <SubscriptionPlan>[
      for (final StoreProduct product in _products)
        if (StoreProducts.periodOf(product.id) case final SubscriptionPeriod period)
          if (seen.add(product.id))
            SubscriptionPlan(
              id: product.id,
              period: period,
              priceLabel: product.priceLabel,
            ),
    ];

    if (plans.isEmpty) {
      // The store spoke and sells none of these. In a Play build that is the
      // console: products missing, still in draft, their base plan not activated,
      // or unpriced in this account's country.
      return const PlanCatalog.unavailable(CatalogProblem.nothingOnSale);
    }

    // Shortest commitment first, whatever order the store answered in. The bloc
    // preselects the yearly plan regardless, so this is about reading order and
    // not about steering.
    plans.sort(
      (SubscriptionPlan a, SubscriptionPlan b) =>
          a.period.index.compareTo(b.period.index),
    );

    return PlanCatalog.offered(plans);
  }

  @override
  Future<PurchaseOutcome> purchase(SubscriptionPlan plan) async {
    if (!_products.any((StoreProduct product) => product.id == plan.id)) {
      return PurchaseOutcome.unavailable;
    }

    final Completer<PurchaseOutcome> completer = Completer<PurchaseOutcome>();
    _pending = completer;

    bool opened;
    try {
      opened = await _billing.buy(plan.id);
    } catch (_) {
      opened = false;
    }

    if (!opened) {
      _pending = null;

      return PurchaseOutcome.failed;
    }

    try {
      return await completer.future.timeout(AppStorePolicy.purchaseWindow);
    } on TimeoutException {
      // Giving up on the answer, not on the purchase: one that completes later
      // still entitles the device through the status listenable.
      return PurchaseOutcome.failed;
    } finally {
      if (_pending == completer) {
        _pending = null;
      }
    }
  }

  /// There is no key to redeem in a store build.
  @override
  Future<PurchaseOutcome> redeemLicenseKey(String key) async =>
      PurchaseOutcome.unavailable;

  @override
  Future<PurchaseOutcome> restore() async {
    _sawEntitlement = false;

    try {
      if (!await _billing.isAvailable()) {
        return PurchaseOutcome.unavailable;
      }

      await _billing.restore();
    } catch (_) {
      return PurchaseOutcome.failed;
    }

    await Future<void>.delayed(AppStorePolicy.restoreWindow);

    if (_sawEntitlement) {
      return PurchaseOutcome.succeeded;
    }

    _status.value = const SubscriptionStatus.free();

    return PurchaseOutcome.nothingToRestore;
  }

  void _onPurchases(List<StorePurchase> purchases) {
    for (final StorePurchase purchase in purchases) {
      // The store may report products this build does not sell — something bought
      // in an older version, say. Ignored rather than treated as an entitlement.
      if (!StoreProducts.isSubscription(purchase.productId)) {
        continue;
      }

      _apply(purchase);

      // Acknowledged even when it was not what the screen was waiting for. A
      // purchase the store is never told about is reversed within days, and the
      // subscriber loses access for no reason they could see.
      if (purchase.needsCompletion) {
        unawaited(_complete(purchase));
      }
    }
  }

  void _apply(StorePurchase purchase) {
    switch (purchase.status) {
      case StorePurchaseStatus.pending:
        // Started and not finished. Reporting it either way would be a lie.
        break;

      case StorePurchaseStatus.purchased:
      case StorePurchaseStatus.restored:
        _sawEntitlement = true;
        // No expiry: the store does not tell the client when the period ends, and
        // inventing one would put a wrong date on the subscription card.
        _status.value = SubscriptionStatus.active(planId: purchase.productId);
        _settle(PurchaseOutcome.succeeded);

      case StorePurchaseStatus.cancelled:
        _settle(PurchaseOutcome.cancelled);

      case StorePurchaseStatus.failed:
        _settle(PurchaseOutcome.failed);
    }
  }

  Future<void> _complete(StorePurchase purchase) async {
    try {
      await _billing.complete(purchase);
    } catch (_) {
      // Nothing useful to do. The store will report it again, and the next
      // attempt will acknowledge it.
    }
  }

  void _settle(PurchaseOutcome outcome) {
    final Completer<PurchaseOutcome>? pending = _pending;

    if (pending == null || pending.isCompleted) {
      return;
    }

    _pending = null;
    pending.complete(outcome);
  }

  /// Only the tests need this: the live instance is app-wide and outlives
  /// everything that could dispose it.
  @visibleForTesting
  Future<void> dispose() async {
    await _purchases.cancel();
    _status.dispose();
  }
}
