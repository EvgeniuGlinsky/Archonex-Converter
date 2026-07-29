import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'package:archonex_converter/project_files/features/subscription/domain/store_billing.dart';

/// [StoreBilling] on top of the `in_app_purchase` plugin.
///
/// Nothing but translation happens here. Every rule about what a purchase means
/// lives in `StoreSubscriptionRepo`, which is what lets those rules be tested
/// without a store — and this file is the only place in the app that knows the
/// plugin exists.
class InAppPurchaseBilling implements StoreBilling {
  InAppPurchaseBilling({InAppPurchase? store})
      : _store = store ?? InAppPurchase.instance;

  final InAppPurchase _store;

  /// The plugin needs the object it handed out to start a purchase, not just an
  /// id, so the last query is kept. A `buy` for something never queried is
  /// refused rather than guessed at.
  final Map<String, ProductDetails> _known = <String, ProductDetails>{};

  @override
  Stream<List<StorePurchase>> get purchases =>
      _store.purchaseStream.map(_translateAll);

  @override
  Future<bool> isAvailable() => _store.isAvailable();

  @override
  Future<List<StoreProduct>> queryProducts(Set<String> ids) async {
    final ProductDetailsResponse response = await _store.queryProductDetails(ids);

    _logAnswer(response, ids);

    // The store answers with one entry per *offer*, not per product: Play returns
    // a separate `ProductDetails` for a subscription's base plan and for each
    // promotional offer on it, all carrying the same product id. First wins here
    // rather than last, which is what `addEntries` used to do — otherwise `buy`
    // silently starts whichever offer the store happened to list last, and which
    // offer a tap purchases changes with the answer's ordering. Duplicates are
    // still handed upward: which of them to show is `StoreSubscriptionRepo`'s
    // rule to make, and it is testable there.
    _known.clear();

    for (final ProductDetails details in response.productDetails) {
      _known.putIfAbsent(details.id, () => details);
    }

    return <StoreProduct>[
      for (final ProductDetails details in response.productDetails)
        StoreProduct(id: details.id, priceLabel: details.price),
    ];
  }

  /// What the store actually said, in a debug build.
  ///
  /// The only place that knows it. Above this file an unsold product and an
  /// unreachable store are two words in an enum; here they are a billing response
  /// code and a list of ids Play did not recognise, which is what tells a missing
  /// console product apart from an inactive base plan. Silent in release: this is
  /// diagnosis, not telemetry, and nothing is sent anywhere.
  void _logAnswer(ProductDetailsResponse response, Set<String> ids) {
    if (!kDebugMode) {
      return;
    }

    final IAPError? error = response.error;

    if (error != null) {
      debugPrint(
        'archonex billing: queryProductDetails failed — '
        '${error.code} ${error.message} ${error.details}',
      );
    }

    if (response.notFoundIDs.isNotEmpty) {
      debugPrint(
        'archonex billing: the store does not sell ${response.notFoundIDs}. '
        'Asked for $ids.',
      );
    }
  }

  @override
  Future<bool> buy(String productId) async {
    final ProductDetails? details = _known[productId];

    if (details == null) {
      return false;
    }

    // A subscription is bought as a non-consumable: it is owned until it lapses,
    // and must never be consumed and re-bought.
    return _store.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: details),
    );
  }

  @override
  Future<void> restore() => _store.restorePurchases();

  @override
  Future<void> complete(StorePurchase purchase) async {
    final PurchaseDetails? details = _awaitingCompletion.remove(purchase);

    if (details == null) {
      return;
    }

    await _store.completePurchase(details);
  }

  /// The plugin's own object for each purchase still to be acknowledged.
  ///
  /// Kept because `completePurchase` needs it and the domain type deliberately
  /// cannot carry it. Entries are removed as they are completed, so this holds
  /// only what is genuinely outstanding.
  final Map<StorePurchase, PurchaseDetails> _awaitingCompletion =
      <StorePurchase, PurchaseDetails>{};

  List<StorePurchase> _translateAll(List<PurchaseDetails> details) =>
      details.map(_translate).toList(growable: false);

  StorePurchase _translate(PurchaseDetails details) {
    final StorePurchase purchase = StorePurchase(
      productId: details.productID,
      status: _status(details.status),
      needsCompletion: details.pendingCompletePurchase,
    );

    if (details.pendingCompletePurchase) {
      _awaitingCompletion[purchase] = details;
    }

    return purchase;
  }

  StorePurchaseStatus _status(PurchaseStatus status) => switch (status) {
        PurchaseStatus.pending => StorePurchaseStatus.pending,
        PurchaseStatus.purchased => StorePurchaseStatus.purchased,
        PurchaseStatus.restored => StorePurchaseStatus.restored,
        PurchaseStatus.canceled => StorePurchaseStatus.cancelled,
        PurchaseStatus.error => StorePurchaseStatus.failed,
      };
}
