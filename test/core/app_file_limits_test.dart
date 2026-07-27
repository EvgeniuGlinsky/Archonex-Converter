import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:archonex/core/constants/app_file_limits.dart';

void main() {
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  void onPlatform(TargetPlatform platform) =>
      debugDefaultTargetPlatformOverride = platform;

  group('the offered ceiling per platform', () {
    test('Android gets 512 MB, well under the 2 GiB array limit', () {
      onPlatform(TargetPlatform.android);

      expect(
        AppFileLimits.maxUploadBytes,
        512 * AppFileLimits.bytesInMegabyte,
      );
      expect(
        AppFileLimits.technicalMaxBytes,
        2 * AppFileLimits.bytesInGigabyte,
      );
    });

    test('iOS gets 1 GB, under the 4 GiB message codec limit', () {
      onPlatform(TargetPlatform.iOS);

      expect(AppFileLimits.maxUploadBytes, AppFileLimits.bytesInGigabyte);
      expect(
        AppFileLimits.technicalMaxBytes,
        4 * AppFileLimits.bytesInGigabyte,
      );
    });

    test('desktop gets 4 GB, and says out loud that it is a phantom limit', () {
      for (final TargetPlatform platform in <TargetPlatform>[
        TargetPlatform.windows,
        TargetPlatform.macOS,
      ]) {
        onPlatform(platform);

        expect(
          AppFileLimits.maxUploadBytes,
          4 * AppFileLimits.bytesInGigabyte,
          reason: '$platform',
        );
        // Nothing in the desktop pipeline is bounded, so a paid tier drops the
        // ceiling rather than raising it.
        expect(AppFileLimits.isPhantomLimit, isTrue, reason: '$platform');
      }
    });

    test('a platform with no engine offers nothing', () {
      onPlatform(TargetPlatform.linux);

      expect(AppFileLimits.maxUploadBytes, 0);
    });

    test('only desktop is phantom — the mobile ceilings are real', () {
      for (final TargetPlatform platform in <TargetPlatform>[
        TargetPlatform.android,
        TargetPlatform.iOS,
      ]) {
        onPlatform(platform);

        expect(AppFileLimits.isPhantomLimit, isFalse, reason: '$platform');
      }
    });
  });

  test('every ceiling stays at or under the free share of its maximum', () {
    for (final TargetPlatform platform in TargetPlatform.values) {
      onPlatform(platform);

      final int offered = AppFileLimits.maxUploadBytes;
      final int maximum = AppFileLimits.technicalMaxBytes;

      expect(
        offered,
        lessThanOrEqualTo((maximum * AppFileLimits.freeTierShare).round()),
        reason: '$platform offers more than the free share of its maximum',
      );
    }
  });

  test('the result ceiling matches the upload ceiling', () {
    // An output can come out larger than its input, and on mobile the output is
    // the one that has to fit in memory — so it cannot be the looser of the two.
    for (final TargetPlatform platform in TargetPlatform.values) {
      onPlatform(platform);

      expect(AppFileLimits.maxResultBytes, AppFileLimits.maxUploadBytes);
    }
  });

  group('the label', () {
    test('is derived from the number, so copy cannot drift from the check', () {
      onPlatform(TargetPlatform.android);
      expect(AppFileLimits.maxUploadLabel, '512 MB');

      onPlatform(TargetPlatform.iOS);
      expect(AppFileLimits.maxUploadLabel, '1 GB');

      onPlatform(TargetPlatform.windows);
      expect(AppFileLimits.maxUploadLabel, '4 GB');
    });

    test('never shows a fraction — every ceiling is a round figure', () {
      for (final TargetPlatform platform in TargetPlatform.values) {
        onPlatform(platform);

        expect(AppFileLimits.maxUploadLabel, isNot(contains('.')));
      }
    });
  });
}
