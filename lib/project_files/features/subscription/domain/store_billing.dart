import 'package:equatable/equatable.dart';

/// How one purchase stands, reduced to the five outcomes this app acts on.
///
/// Deliberately not the plugin's own enum. Keeping the platform's vocabulary out
/// of `domain/` is what lets the rules below be tested with a hand written fake
/// instead of a real store, and it means a plugin upgrade that renames a status
/// touches one adapter rather than every rule.
enum StorePurchaseStatus {
  /// Started and not finished — a bank asking for confirmation, say. Not a
  /// result, and must not be reported as one.
  pending,

  purchased,

  /// Already owned, handed back in answer to a restore.
  restored,

  cancelled,

  failed,
}

/// One product, priced by the store.
///
/// [priceLabel] arrives already formatted for the user's country and currency.
/// It is never composed in the app: a hand-built price string is how an app ends
/// up advertising a number the store does not charge.
final class StoreProduct extends Equatable {
  const StoreProduct({required this.id, required this.priceLabel});

  final String id;
  final String priceLabel;

  @override
  List<Object?> get props => <Object?>[id, priceLabel];
}

final class StorePurchase extends Equatable {
  const StorePurchase({
    required this.productId,
    required this.status,
    this.needsCompletion = false,
  });

  final String productId;
  final StorePurchaseStatus status;

  /// Whether the store is still waiting to be told this was handled.
  ///
  /// Not optional bookkeeping: Google reverses a purchase that is never
  /// acknowledged, so a subscriber who paid would be refunded within days and
  /// lose access for no reason they could see.
  final bool needsCompletion;

  bool get isEntitling =>
      status == StorePurchaseStatus.purchased ||
      status == StorePurchaseStatus.restored;

  @override
  List<Object?> get props => <Object?>[productId, status, needsCompletion];
}

/// Store billing, as much of it as this app needs.
///
/// Everything arrives through [purchases] rather than by returning from the call
/// that caused it — including purchases the app never asked for, such as one
/// completed on another device or a renewal that went through overnight. That is
/// the store's design, not a wrapper's choice, and the repository above is shaped
/// around it.
abstract interface class StoreBilling {
  /// Every purchase the store has anything to say about. Broadcast, and live for
  /// as long as the app is.
  Stream<List<StorePurchase>> get purchases;

  /// Whether this device has store billing at all. `false` on a build the store
  /// did not install, and on a device with no store on it.
  Future<bool> isAvailable();

  Future<List<StoreProduct>> queryProducts(Set<String> ids);

  /// Opens the store's purchase sheet. The answer arrives through [purchases].
  ///
  /// Returns whether the sheet opened, which is not whether anything was bought.
  Future<bool> buy(String productId);

  /// Asks the store to re-send what this account already owns, through
  /// [purchases].
  Future<void> restore();

  /// Tells the store the purchase has been handled.
  Future<void> complete(StorePurchase purchase);
}
