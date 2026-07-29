import 'package:flutter/foundation.dart';

/// How much converting the free tier includes, and where it is metered at all.
///
/// Unlike everything in `AppFileLimits`, none of this is a technical bound.
/// The file *size* ceilings are the real maximum each platform can carry and
/// are offered in full — where the product is gated, it is gated by how many
/// files are converted, never by how large they are.
///
/// **Android is not metered.** Selling a subscription there was tried and set
/// aside, and a count nobody can lift is worse than no count: the paywall it
/// pointed at could never take a payment. The alternative — deleting the quota
/// feature outright — was rejected because metering is still how the desktop
/// builds are meant to work, and restoring a deleted feature from git costs
/// more than a platform tier does. Everything below the [isMetered] check
/// stays live and tested; only Android skips it.
class AppQuotaLimits {
  const AppQuotaLimits._();

  /// Source files a metered platform's free tier may convert per calendar
  /// month.
  ///
  /// Counted on the input rather than the output: a batch of five photos is
  /// five, and one PDF exploded into twelve pages is one. What the user handed
  /// over is what they can predict; how many files come back out is a property
  /// of the conversion they chose.
  ///
  /// The product decision, unchanged by platform. Read this rather than
  /// [freeFilesPerMonth] when the number is only being *described* — the
  /// paywall's own copy does, so it never has to render a sentinel.
  static const int meteredFilesPerMonth = 10;

  /// A count lifted entirely rather than raised.
  ///
  /// Represented as its own name so no call site has to know that "unlimited"
  /// is spelled with a sentinel number.
  static const int unlimited = -1;

  /// What this platform actually allows per month.
  static int get freeFilesPerMonth =>
      isMetered ? meteredFilesPerMonth : unlimited;

  /// Whether conversions are counted here at all.
  ///
  /// Read through `defaultTargetPlatform` rather than `Platform.isAndroid`,
  /// because the second is always false on the test host: the check would pass
  /// every test while changing what ships. Tests pin the platform they mean
  /// with `debugDefaultTargetPlatformOverride`, the way `AppFileLimits` is
  /// already tested.
  static bool get isMetered =>
      kIsWeb || defaultTargetPlatform != TargetPlatform.android;
}
