import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:archonex_converter/core/constants/app_file_limits.dart';

void main() {
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  void onPlatform(TargetPlatform platform) =>
      debugDefaultTargetPlatformOverride = platform;

  group('the ceiling per platform', () {
    test('Android bounds neither side — the source or the result', () {
      onPlatform(TargetPlatform.android);

      // The source is read by path and the result is copied into a folder the
      // user picks, so nothing is ever resident on either side: a five gigabyte
      // video may be picked, converted and saved. The 2 GiB `byte[]` ceiling
      // survives only on the fallback save path, where it arrives as an
      // `OutOfMemoryError` rather than as a number checked in advance — see
      // `IoFileSaver.saveOne`.
      expect(AppFileLimits.maxUploadBytes, AppFileLimits.bytesInTerabyte);
      expect(AppFileLimits.limitsSourceSize, isFalse);

      expect(AppFileLimits.maxResultBytes, AppFileLimits.bytesInTerabyte);
      expect(AppFileLimits.technicalMaxBytes, AppFileLimits.bytesInTerabyte);
      expect(AppFileLimits.limitsResultSize, isFalse);
    });

    test('iOS is the last platform with a real ceiling, at the 4 GiB codec limit',
        () {
      // `saveFile` throws there without `bytes`, and no folder route replaces it,
      // so the whole result really does have to be resident at once.
      onPlatform(TargetPlatform.iOS);

      expect(
        AppFileLimits.maxUploadBytes,
        4 * AppFileLimits.bytesInGigabyte,
      );
      expect(
        AppFileLimits.technicalMaxBytes,
        4 * AppFileLimits.bytesInGigabyte,
      );
      expect(AppFileLimits.limitsResultSize, isTrue);
    });

    test('desktop has no real ceiling, so it gets a figure no file reaches',
        () {
      // Linux is here too. The tier answers how large a file can be saved, not
      // which engines exist: its save path is the same OS-level copy, and the
      // PDF converter needs no FFmpeg to run there.
      for (final TargetPlatform platform in <TargetPlatform>[
        TargetPlatform.windows,
        TargetPlatform.macOS,
        TargetPlatform.linux,
      ]) {
        onPlatform(platform);

        expect(
          AppFileLimits.maxUploadBytes,
          AppFileLimits.bytesInTerabyte,
          reason: '$platform',
        );
      }
    });

    test('a platform the app does not target offers nothing', () {
      onPlatform(TargetPlatform.fuchsia);

      expect(AppFileLimits.maxUploadBytes, 0);
    });
  });

  group('the batch ceiling', () {
    test('Android takes as many files as the user cares to add', () {
      onPlatform(TargetPlatform.android);

      expect(AppFileLimits.maxBatchFiles, AppFileLimits.unlimitedBatch);
      expect(AppFileLimits.isBatchLimited, isFalse);
    });

    test('iOS stays at a number the fallback save path can survive', () {
      // If the chosen folder turns out to be unwritable the app falls back to
      // one dialog per file, so the count has to stay tappable.
      onPlatform(TargetPlatform.iOS);

      expect(AppFileLimits.maxBatchFiles, 30);
      expect(AppFileLimits.isBatchLimited, isTrue);
    });

    test('desktop takes more, because it never needs that fallback', () {
      onPlatform(TargetPlatform.windows);

      expect(AppFileLimits.maxBatchFiles, 100);
    });

    test('a platform the app does not target accepts no batch at all', () {
      onPlatform(TargetPlatform.fuchsia);

      // Zero, and enforced — the opposite of unlimited, which shares the shape
      // of "no number to compare against" and must not share the meaning.
      expect(AppFileLimits.maxBatchFiles, 0);
      expect(AppFileLimits.isBatchLimited, isTrue);
    });

    test('a platform that can convert can always take at least one file', () {
      for (final TargetPlatform platform in TargetPlatform.values) {
        onPlatform(platform);

        if (AppFileLimits.maxUploadBytes == 0) {
          continue;
        }

        expect(
          AppFileLimits.isBatchLimited
              ? AppFileLimits.maxBatchFiles
              : 1,
          greaterThan(0),
          reason: '$platform accepts a file but not a batch',
        );
      }
    });
  });

  test('the result ceiling is never looser than the upload ceiling', () {
    // An output can come out larger than its input, and on mobile the output is
    // the one that has to fit in memory — so it can be the tighter of the two
    // but never the looser one.
    for (final TargetPlatform platform in TargetPlatform.values) {
      onPlatform(platform);

      expect(
        AppFileLimits.maxResultBytes,
        lessThanOrEqualTo(AppFileLimits.maxUploadBytes),
        reason: '$platform',
      );
    }
  });

  group('the label', () {
    test('is derived from the number, so copy cannot drift from the check', () {
      // iOS is the only platform left with a ceiling worth announcing, which is
      // why it is the only one whose label reaches a screen — see
      // `ConverterLimitsUi`, which returns null for the other two.
      onPlatform(TargetPlatform.iOS);
      expect(AppFileLimits.maxUploadLabel, '4 GB');
      expect(AppFileLimits.maxResultLabel, '4 GB');

      onPlatform(TargetPlatform.android);
      expect(AppFileLimits.maxResultLabel, '1 TB');

      onPlatform(TargetPlatform.windows);
      expect(AppFileLimits.maxUploadLabel, '1 TB');
    });

    test('is announced on exactly the platforms that enforce something', () {
      // The pair of getters copy reads before naming a number. Getting these
      // backwards is how a screen promises a limit that does not exist, which is
      // the whole reason they are separate from the numbers.
      for (final TargetPlatform platform in TargetPlatform.values) {
        onPlatform(platform);

        expect(
          AppFileLimits.limitsResultSize,
          AppFileLimits.maxResultBytes < AppFileLimits.bytesInTerabyte,
          reason: '$platform',
        );
      }
    });

    test('never shows a fraction — every ceiling is a round figure', () {
      for (final TargetPlatform platform in TargetPlatform.values) {
        onPlatform(platform);

        expect(AppFileLimits.maxUploadLabel, isNot(contains('.')));
        expect(AppFileLimits.maxResultLabel, isNot(contains('.')));
      }
    });
  });
}
