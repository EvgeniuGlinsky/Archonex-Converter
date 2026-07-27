import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:archonex_converter/core/constants/app_file_limits.dart';

void main() {
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  void onPlatform(TargetPlatform platform) =>
      debugDefaultTargetPlatformOverride = platform;

  group('the ceiling per platform', () {
    test('Android gets the full 2 GiB array limit', () {
      onPlatform(TargetPlatform.android);

      expect(
        AppFileLimits.maxUploadBytes,
        2 * AppFileLimits.bytesInGigabyte,
      );
      expect(
        AppFileLimits.technicalMaxBytes,
        2 * AppFileLimits.bytesInGigabyte,
      );
    });

    test('iOS gets the full 4 GiB message codec limit', () {
      onPlatform(TargetPlatform.iOS);

      expect(
        AppFileLimits.maxUploadBytes,
        4 * AppFileLimits.bytesInGigabyte,
      );
      expect(
        AppFileLimits.technicalMaxBytes,
        4 * AppFileLimits.bytesInGigabyte,
      );
    });

    test('desktop has no real ceiling, so it gets a figure no file reaches',
        () {
      for (final TargetPlatform platform in <TargetPlatform>[
        TargetPlatform.windows,
        TargetPlatform.macOS,
      ]) {
        onPlatform(platform);

        expect(
          AppFileLimits.maxUploadBytes,
          AppFileLimits.bytesInTerabyte,
          reason: '$platform',
        );
      }
    });

    test('a platform with no engine offers nothing', () {
      onPlatform(TargetPlatform.linux);

      expect(AppFileLimits.maxUploadBytes, 0);
    });
  });

  group('the batch ceiling', () {
    test('mobile stays at a number the fallback save path can survive', () {
      // If the chosen folder turns out to be unwritable the app falls back to
      // one dialog per file, so the count has to stay tappable.
      for (final TargetPlatform platform in <TargetPlatform>[
        TargetPlatform.android,
        TargetPlatform.iOS,
      ]) {
        onPlatform(platform);

        expect(AppFileLimits.maxBatchFiles, 30, reason: '$platform');
      }
    });

    test('desktop takes more, because it never needs that fallback', () {
      onPlatform(TargetPlatform.windows);

      expect(AppFileLimits.maxBatchFiles, 100);
    });

    test('a platform with no engine accepts no batch at all', () {
      onPlatform(TargetPlatform.linux);

      expect(AppFileLimits.maxBatchFiles, 0);
    });

    test('a platform that can convert can always take at least one file', () {
      for (final TargetPlatform platform in TargetPlatform.values) {
        onPlatform(platform);

        if (AppFileLimits.maxUploadBytes == 0) {
          continue;
        }

        expect(
          AppFileLimits.maxBatchFiles,
          greaterThan(0),
          reason: '$platform accepts a file but not a batch',
        );
      }
    });
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
      expect(AppFileLimits.maxUploadLabel, '2 GB');

      onPlatform(TargetPlatform.iOS);
      expect(AppFileLimits.maxUploadLabel, '4 GB');

      onPlatform(TargetPlatform.windows);
      expect(AppFileLimits.maxUploadLabel, '1 TB');
    });

    test('never shows a fraction — every ceiling is a round figure', () {
      for (final TargetPlatform platform in TargetPlatform.values) {
        onPlatform(platform);

        expect(AppFileLimits.maxUploadLabel, isNot(contains('.')));
      }
    });
  });
}
