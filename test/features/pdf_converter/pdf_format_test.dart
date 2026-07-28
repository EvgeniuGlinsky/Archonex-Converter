import 'package:flutter_test/flutter_test.dart';

import 'package:archonex_converter/project_files/features/pdf_converter/domain/models/pdf_format.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/domain/models/pdf_target.dart';

void main() {
  group('resolving an extension', () {
    test('finds the canonical one', () {
      expect(PdfFormat.fromExtension('pdf'), PdfFormat.pdf);
      expect(PdfFormat.fromExtension('png'), PdfFormat.png);
      expect(PdfFormat.fromExtension('txt'), PdfFormat.txt);
    });

    test('finds aliases and ignores case', () {
      expect(PdfFormat.fromExtension('jpeg'), PdfFormat.jpg);
      expect(PdfFormat.fromExtension('TIF'), PdfFormat.tiff);
      expect(PdfFormat.fromExtension('Markdown'), PdfFormat.md);
    });

    test('refuses anything else', () {
      expect(PdfFormat.fromExtension('docx'), isNull);
      expect(PdfFormat.fromExtension(''), isNull);
    });

    test('every alias is pickable', () {
      for (final PdfFormat format in PdfFormat.values) {
        for (final String extension in format.extensions) {
          expect(
            PdfFormat.pickableExtensions,
            contains(extension),
            reason: '$format.$extension',
          );
        }
      }
    });
  });

  group('the kind of a batch', () {
    test('is the one kind they all share', () {
      expect(
        PdfFormat.sharedKind(<PdfFormat>[PdfFormat.png, PdfFormat.jpg]),
        PdfSourceKind.image,
      );
      expect(
        PdfFormat.sharedKind(<PdfFormat>[PdfFormat.txt, PdfFormat.md]),
        PdfSourceKind.text,
      );
    });

    test('is null when they disagree, because there is no direction then', () {
      expect(
        PdfFormat.sharedKind(<PdfFormat>[PdfFormat.png, PdfFormat.pdf]),
        isNull,
      );
    });

    test('is null for an empty batch', () {
      expect(PdfFormat.sharedKind(const <PdfFormat>[]), isNull);
    });
  });

  group('what a batch can become', () {
    test('pictures and text go into a PDF', () {
      expect(
        PdfTarget.targetsFor(PdfSourceKind.image),
        const <PdfTarget>[PdfTarget.pdf],
      );
      expect(
        PdfTarget.targetsFor(PdfSourceKind.text),
        const <PdfTarget>[PdfTarget.pdf],
      );
    });

    test('a PDF comes out as pictures', () {
      expect(
        PdfTarget.targetsFor(PdfSourceKind.pdf),
        const <PdfTarget>[PdfTarget.png, PdfTarget.jpg],
      );
    });

    test('a batch with no direction can become nothing', () {
      expect(PdfTarget.targetsFor(null), isEmpty);
    });

    test('aiming at a PDF merges, aiming at a picture does not', () {
      expect(PdfTarget.pdf.mergesBatch, isTrue);
      expect(PdfTarget.png.mergesBatch, isFalse);
      expect(PdfTarget.jpg.mergesBatch, isFalse);
    });

    test('only JPG has a quality dial', () {
      expect(PdfTarget.jpg.supportsQuality, isTrue);
      expect(PdfTarget.png.supportsQuality, isFalse);
      expect(PdfTarget.pdf.supportsQuality, isFalse);
    });
  });
}
