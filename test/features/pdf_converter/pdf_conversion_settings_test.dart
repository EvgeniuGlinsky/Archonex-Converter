import 'package:flutter_test/flutter_test.dart';

import 'package:archonex_converter/project_files/features/pdf_converter/domain/models/pdf_conversion_settings.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/domain/models/pdf_page_size.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/domain/models/pdf_target.dart';

void main() {
  group('which settings a direction can use', () {
    test('page geometry only applies while writing a PDF', () {
      const PdfConversionSettings settings = PdfConversionSettings();

      expect(settings.appliesPageSizeFor(PdfTarget.pdf), isTrue);
      expect(settings.appliesPageSizeFor(PdfTarget.png), isFalse);
    });

    test('resolution only applies while reading one out', () {
      const PdfConversionSettings settings = PdfConversionSettings();

      expect(settings.appliesRasterDpiFor(PdfTarget.png), isTrue);
      expect(settings.appliesRasterDpiFor(PdfTarget.pdf), isFalse);
    });

    test('quality needs both a picture target and a dial on it', () {
      const PdfConversionSettings settings = PdfConversionSettings();

      expect(settings.appliesQualityFor(PdfTarget.jpg), isTrue);
      expect(settings.appliesQualityFor(PdfTarget.png), isFalse);
      expect(settings.appliesQualityFor(PdfTarget.pdf), isFalse);
    });
  });

  group('pruning for a target', () {
    test('a value tuned for one direction cannot survive into the other', () {
      const PdfConversionSettings tuned = PdfConversionSettings(
        pageSize: PdfPageSize.a4,
        marginPoints: 56,
        rasterDpi: 600,
        quality: 40,
      );

      final PdfConversionSettings asPdf = tuned.prunedFor(PdfTarget.pdf);

      expect(asPdf.pageSize, PdfPageSize.a4);
      expect(asPdf.marginPoints, 56);
      // Resolution and quality mean nothing when writing a PDF.
      expect(asPdf.rasterDpi, PdfConversionSettings.defaultRasterDpi);
      expect(asPdf.quality, PdfConversionSettings.defaultQuality);
    });

    test('the other way round drops the page geometry', () {
      const PdfConversionSettings tuned = PdfConversionSettings(
        pageSize: PdfPageSize.letter,
        marginPoints: 56,
        rasterDpi: 300,
        quality: 40,
      );

      final PdfConversionSettings asJpg = tuned.prunedFor(PdfTarget.jpg);

      expect(asJpg.pageSize, PdfPageSize.fitSource);
      expect(asJpg.marginPoints, PdfConversionSettings.defaultMarginPoints);
      expect(asJpg.rasterDpi, 300);
      expect(asJpg.quality, 40);
    });

    test('PNG keeps the resolution but loses the quality dial', () {
      const PdfConversionSettings tuned = PdfConversionSettings(
        rasterDpi: 300,
        quality: 40,
      );

      final PdfConversionSettings asPng = tuned.prunedFor(PdfTarget.png);

      expect(asPng.rasterDpi, 300);
      expect(asPng.quality, PdfConversionSettings.defaultQuality);
    });

    test('pruning twice changes nothing more', () {
      const PdfConversionSettings tuned = PdfConversionSettings(
        pageSize: PdfPageSize.a4,
        rasterDpi: 600,
      );

      final PdfConversionSettings once = tuned.prunedFor(PdfTarget.pdf);

      expect(once.prunedFor(PdfTarget.pdf), once);
    });
  });

  test('quality is clamped to the shared scale', () {
    const PdfConversionSettings settings = PdfConversionSettings();

    expect(settings.copyWith(quality: 500).quality, 100);
    expect(settings.copyWith(quality: -5).quality, 0);
  });
}
