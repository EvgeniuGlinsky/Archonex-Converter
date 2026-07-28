/// How this build takes money, which decides what the paywall shows.
///
/// The two paid channels look nothing alike on screen — one taps a store
/// sheet, the other opens a browser and comes back with a key to paste — so
/// the choice is made once, at the platform boundary, rather than by scattering
/// `Platform.isWindows` through the widget tree.
enum PurchaseChannel {
  /// Google Play, the App Store or the Mac App Store handle the payment.
  store,

  /// This platform can be paid for, but not by this copy of the app.
  ///
  /// A store will only serve billing to a build it installed and signed itself,
  /// so an APK downloaded from GitHub can never complete a purchase. Saying where
  /// the paid version lives is the one useful thing this screen can do, and it
  /// beats a button that fails.
  storeBuildOnly,

  /// Bought outside the app, unlocked here with a licence key. Reserved for the
  /// platforms no store reaches — see `LicenseGateway`.
  licenseKey,

  /// Nothing to sell here at all.
  unavailable,
}
