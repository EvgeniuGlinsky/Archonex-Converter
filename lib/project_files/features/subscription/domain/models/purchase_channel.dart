/// How this build takes money, which decides what the paywall shows.
///
/// The two paid channels look nothing alike on screen — one taps a store
/// sheet, the other opens a browser and comes back with a key to paste — so
/// the choice is made once, at the platform boundary, rather than by scattering
/// `Platform.isWindows` through the widget tree.
enum PurchaseChannel {
  /// Google Play, the App Store or the Mac App Store handle the payment.
  store,

  /// Bought on the web, unlocked in the app with a licence key. The only route
  /// on Windows and Linux, where no store billing exists.
  licenseKey,

  /// Nothing to sell here — the web build, which has no converters either.
  unavailable,
}
