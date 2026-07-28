/// Opens the checkout page outside the app.
///
/// An interface for one line of plugin code, because that line is the whole
/// difference between a testable purchase and one that can only be tried by
/// hand: a widget test must be able to prove the button opened the right URL
/// without a browser existing.
abstract interface class CheckoutLauncher {
  /// Returns `false` when nothing on this device could open [url].
  Future<bool> open(Uri url);
}
