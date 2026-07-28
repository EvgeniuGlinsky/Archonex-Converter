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

    _known
      ..clear()
      ..addEntries(
        response.productDetails.map(
          (ProductDetails details) =>
              MapEntry<String, ProductDetails>(details.id, details),
        ),
      );

    // `notFoundIDs` is the normal answer for a product that exists in the console
    // but is not yet live in this track, so it is reported rather than thrown.
    return <StoreProduct>[
      for (final ProductDetails details in response.productDetails)
        StoreProduct(id: details.id, priceLabel: details.price),
    ];
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
