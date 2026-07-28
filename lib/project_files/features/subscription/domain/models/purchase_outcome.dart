/// How an attempt to buy, redeem or restore ended.
///
/// Closing the store sheet is [cancelled], not a failure: it is the user
/// changing their mind, and reporting it as an error would be a lie.
enum PurchaseOutcome {
  /// The device is entitled now. The new status arrives through the repo's
  /// listenable rather than through this value.
  succeeded,

  cancelled,

  /// The checkout page was handed to the browser, and that is all that
  /// happened.
  ///
  /// Not a success and not a failure: payment finishes outside the app, and the
  /// entitlement arrives later, when the key it produced is redeemed. Reporting
  /// this as success would claim a purchase that has not been made.
  checkoutOpened,

  /// Nothing was found to restore, or the key had no active subscription.
  nothingToRestore,

  /// A real key whose subscription has ended, been refunded or been cancelled.
  ///
  /// Distinct from [invalidLicenseKey] because the person holding it did once
  /// pay, and telling them their key is bad would be both wrong and insulting.
  subscriptionLapsed,

  /// The key is malformed, belongs to another product, or has used up its
  /// activation slots.
  invalidLicenseKey,

  /// No purchase route exists in this build yet.
  unavailable,

  failed,
}
