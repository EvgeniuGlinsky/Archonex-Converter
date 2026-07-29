import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:archonex_converter/core/constants/app_quota_limits.dart';

void main() {
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  void onPlatform(TargetPlatform platform) =>
      debugDefaultTargetPlatformOverride = platform;

  test('Android counts nothing, because nothing there lifts a count', () {
    onPlatform(TargetPlatform.android);

    expect(AppQuotaLimits.isMetered, isFalse);
    expect(AppQuotaLimits.freeFilesPerMonth, AppQuotaLimits.unlimited);
  });

  test('every other platform still meters', () {
    for (final TargetPlatform platform in TargetPlatform.values) {
      if (platform == TargetPlatform.android) {
        continue;
      }

      onPlatform(platform);

      expect(AppQuotaLimits.isMetered, isTrue, reason: '$platform');
      expect(
        AppQuotaLimits.freeFilesPerMonth,
        AppQuotaLimits.meteredFilesPerMonth,
        reason: '$platform',
      );
    }
  });

  test('the number a paywall describes does not move with the platform', () {
    // `paywallSubtitle` interpolates it. Reading the platform-aware getter
    // there would print the sentinel on a platform that never counts.
    onPlatform(TargetPlatform.android);
    expect(AppQuotaLimits.meteredFilesPerMonth, 10);

    onPlatform(TargetPlatform.windows);
    expect(AppQuotaLimits.meteredFilesPerMonth, 10);
  });
}
