import 'package:flutter_test/flutter_test.dart';

import 'package:archonex/project_files/features/image_converter/data/ffmpeg/ffmpeg_image_target_spec.dart';
import 'package:archonex/project_files/features/image_converter/domain/models/image_format.dart';

void main() {
  group('lookup', () {
    test('resolves every canonical extension', () {
      for (final ImageFormat format in ImageFormat.values) {
        expect(
          ImageFormat.fromExtension(format.extension),
          format,
          reason: '${format.extension} did not resolve',
        );
      }
    });

    test('resolves the aliases photos actually arrive with', () {
      expect(ImageFormat.fromExtension('jpeg'), ImageFormat.jpg);
      expect(ImageFormat.fromExtension('tif'), ImageFormat.tiff);
      expect(ImageFormat.fromExtension('heif'), ImageFormat.heic);
    });

    test('ignores the case of the extension', () {
      expect(ImageFormat.fromExtension('JPEG'), ImageFormat.jpg);
      expect(ImageFormat.fromExtension('PNG'), ImageFormat.png);
    });

    test('returns nothing for an extension it does not know', () {
      expect(ImageFormat.fromExtension('psd'), isNull);
      expect(ImageFormat.fromExtension(''), isNull);
    });

    test('offers every alias to the picker', () {
      expect(ImageFormat.pickableExtensions, contains('jpg'));
      expect(ImageFormat.pickableExtensions, contains('jpeg'));
      expect(ImageFormat.pickableExtensions, contains('heic'));
    });
  });

  group('targets', () {
    test('never offer a format as a conversion of itself', () {
      for (final ImageFormat format in ImageFormat.values) {
        expect(format.targets, isNot(contains(format)), reason: format.label);
      }
    });

    test('never offer a format nothing can write', () {
      for (final ImageFormat format in ImageFormat.values) {
        expect(
          format.targets.every((target) => target.canEncode),
          isTrue,
          reason: '${format.label} offers a target with no encoder',
        );
      }
    });

    test('a read only source can still be converted away from', () {
      // The whole point of reading HEIC is getting out of it.
      expect(ImageFormat.heic.targets, contains(ImageFormat.jpg));
      expect(ImageFormat.heic.targets, contains(ImageFormat.png));
    });

    test('a mixed batch keeps every writable format', () {
      final List<ImageFormat> targets = ImageFormat.targetsFor(
        <ImageFormat>[ImageFormat.png, ImageFormat.jpg],
      );

      // Neither is dropped: converting the PNGs to JPG is a real request even
      // though some of the batch is already JPG.
      expect(targets, contains(ImageFormat.jpg));
      expect(targets, contains(ImageFormat.png));
      expect(targets, contains(ImageFormat.webp));
    });

    test('a single format batch does not offer that format', () {
      final List<ImageFormat> targets =
          ImageFormat.targetsFor(<ImageFormat>[ImageFormat.png]);

      expect(targets, isNot(contains(ImageFormat.png)));
      expect(targets, contains(ImageFormat.jpg));
    });
  });

  group('capabilities', () {
    test('every reachable target has an encoder spec', () {
      for (final ImageFormat source in ImageFormat.values) {
        for (final ImageFormat target in source.targets) {
          expect(
            FfmpegImageTargetSpec.of(target),
            isNotNull,
            reason: '${target.label} is offered but cannot be produced',
          );
        }
      }
    });

    test('a format with no encoder has no spec either', () {
      for (final ImageFormat format in ImageFormat.values) {
        if (format.canEncode) {
          continue;
        }

        expect(
          FfmpegImageTargetSpec.of(format),
          isNull,
          reason: '${format.label} claims to be unwritable but has a spec',
        );
      }
    });

    test('only the lossy formats offer a quality dial', () {
      expect(ImageFormat.jpg.supportsQuality, isTrue);
      expect(ImageFormat.webp.supportsQuality, isTrue);
      expect(ImageFormat.png.supportsQuality, isFalse);
      expect(ImageFormat.tiff.supportsQuality, isFalse);
      // GIF's size comes from its palette, not from a quality number.
      expect(ImageFormat.gif.supportsQuality, isFalse);
    });

    test('flattening is asked about only when transparency would be lost', () {
      expect(ImageFormat.jpg.needsBackgroundFrom(ImageFormat.png), isTrue);
      // The source has no alpha to begin with.
      expect(ImageFormat.jpg.needsBackgroundFrom(ImageFormat.jpg), isFalse);
      // The target keeps it.
      expect(ImageFormat.webp.needsBackgroundFrom(ImageFormat.png), isFalse);
    });
  });
}
