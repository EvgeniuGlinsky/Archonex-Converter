import 'package:flutter_test/flutter_test.dart';

import 'package:archonex_converter/project_files/features/image_converter/domain/models/image_background.dart';
import 'package:archonex_converter/project_files/features/image_converter/domain/models/image_conversion_settings.dart';
import 'package:archonex_converter/project_files/features/image_converter/domain/models/image_dimension_limit.dart';
import 'package:archonex_converter/project_files/features/image_converter/domain/models/image_format.dart';
import 'package:archonex_converter/project_files/features/image_converter/domain/models/image_quality.dart';

void main() {
  group('deferring to the preset', () {
    test('a fresh set of settings defers everything', () {
      expect(const ImageConversionSettings().isPresetOnly, isTrue);
    });

    test('every advanced field breaks the deferral on its own', () {
      const List<ImageConversionSettings> overrides = <ImageConversionSettings>[
        ImageConversionSettings(dimensionLimit: ImageDimensionLimit.px1920),
        ImageConversionSettings(imageQuality: 50),
        ImageConversionSettings(background: ImageBackground.black),
        ImageConversionSettings(keepMetadata: true),
      ];

      for (final ImageConversionSettings settings in overrides) {
        expect(settings.isPresetOnly, isFalse);
      }
    });

    test('quality follows the preset until it is overridden', () {
      const ImageConversionSettings settings = ImageConversionSettings(
        quality: ImageQuality.compact,
      );

      expect(settings.effectiveQuality, ImageQuality.compact.quality);
      expect(
        settings.copyWith(imageQuality: 71).effectiveQuality,
        71,
      );
    });

    test('the size cap follows the preset until it is overridden', () {
      const ImageConversionSettings settings = ImageConversionSettings(
        quality: ImageQuality.balanced,
      );

      expect(settings.effectiveMaxSide, ImageQuality.balanced.maxSide);
      expect(
        settings
            .copyWith(dimensionLimit: ImageDimensionLimit.px800)
            .effectiveMaxSide,
        800,
      );
    });

    test('Original means no cap even when the preset has one', () {
      const ImageConversionSettings settings = ImageConversionSettings(
        quality: ImageQuality.compact,
        dimensionLimit: ImageDimensionLimit.original,
      );

      expect(settings.effectiveMaxSide, isNull);
    });

    test('resetting keeps the preset and drops everything else', () {
      const ImageConversionSettings settings = ImageConversionSettings(
        quality: ImageQuality.high,
        dimensionLimit: ImageDimensionLimit.px800,
        imageQuality: 40,
        keepMetadata: true,
      );

      final ImageConversionSettings reset = settings.resetToPreset();

      expect(reset.quality, ImageQuality.high);
      expect(reset.isPresetOnly, isTrue);
    });
  });

  group('pruning for a target', () {
    test('a lossless target drops the quality override', () {
      const ImageConversionSettings settings = ImageConversionSettings(
        imageQuality: 40,
      );

      expect(settings.prunedFor(ImageFormat.png).imageQuality, isNull);
      expect(settings.prunedFor(ImageFormat.jpg).imageQuality, 40);
    });

    test('a target that keeps transparency drops the backdrop', () {
      const ImageConversionSettings settings = ImageConversionSettings(
        background: ImageBackground.black,
      );

      expect(
        settings.prunedFor(ImageFormat.png).background,
        ImageBackground.white,
      );
      expect(
        settings.prunedFor(ImageFormat.jpg).background,
        ImageBackground.black,
      );
    });

    test('the size cap survives every target, because they all resize', () {
      const ImageConversionSettings settings = ImageConversionSettings(
        dimensionLimit: ImageDimensionLimit.px1280,
      );

      for (final ImageFormat target in ImageFormat.values) {
        expect(
          settings.prunedFor(target).dimensionLimit,
          ImageDimensionLimit.px1280,
          reason: '${target.label} dropped the size cap',
        );
      }
    });

    test('pruning a preset only set changes nothing', () {
      const ImageConversionSettings settings = ImageConversionSettings();

      for (final ImageFormat target in ImageFormat.values) {
        expect(settings.prunedFor(target), settings, reason: target.label);
      }
    });
  });
}
