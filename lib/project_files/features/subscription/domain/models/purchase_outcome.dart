/// How an attempt to buy, redeem or restore ended.
///
/// Closing the store sheet is [cancelled], not a failure: it is the user
/// changing their mind, and reporting it as an error would be a lie.
enum PurchaseOutcome {
  /// The device is entitled now. The new status arrives through the repo's
  /// listenable rather than through this value.
  succeeded,

  cancelled,

  /// Nothing was found to restore, or the key had no active subscription.
  nothingToRestore,

  /// The key is malformed, belongs to another product, or has used up its
  /// activation slots.
  invalidLicenseKey,

  /// No purchase route exists in this build yet.
  unavailable,

  failed,
}
