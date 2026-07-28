/// How long the app waits on a store that answers out of band.
///
/// The billing plugin reports everything through one broadcast stream rather
/// than by returning from the call that caused it, so "did anything come back"
/// can only be answered by waiting. Both numbers below are that wait, and both
/// are chosen so the wrong answer costs as little as possible.
class AppStorePolicy {
  const AppStorePolicy._();

  /// How long a restore is given to produce a purchase before the device is
  /// treated as not subscribed.
  ///
  /// This is the only way a cancelled subscription is ever noticed, so it cannot
  /// be skipped — but it also runs on the splash screen, so it cannot be long.
  /// Two seconds is enough for a local cache hit, which is what the store
  /// answers from in the overwhelming majority of launches. A slow answer that
  /// arrives late still entitles the device the moment it lands: the status is a
  /// listenable, and every screen is watching it.
  static const Duration restoreWindow = Duration(seconds: 2);

  /// How long a purchase may stay in flight before the screen stops waiting.
  ///
  /// Generous on purpose. The store sheet is the user's to take their time over
  /// — adding a card, confirming a fingerprint — and this is only a backstop
  /// against a stream that never speaks at all. Giving up here does not cancel
  /// anything: a purchase that completes afterwards still arrives through the
  /// status listenable.
  static const Duration purchaseWindow = Duration(minutes: 3);
}
