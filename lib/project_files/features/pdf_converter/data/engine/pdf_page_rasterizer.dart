import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:printing/printing.dart';

import 'package:archonex_converter/project_files/features/pdf_converter/domain/models/pdf_target.dart';

/// Renders the pages of a PDF out as picture files.
///
/// Unlike [PdfDocumentWriter] this cannot move to a background isolate:
/// `Printing.raster` is a plugin call and plugins are bound to the root
/// isolate. That costs nothing, because the rendering itself happens in PDFium
/// on the native side and never occupies the Dart thread. Encoding the pixels
/// afterwards does, so that part is pushed onto an isolate.
class PdfPageRasterizer {
  const PdfPageRasterizer();

  /// Renders [documentBytes] and writes one file per page into [directory].
  ///
  /// Emits each finished file as it lands rather than collecting them, so a
  /// hundred page document shows progress instead of a long blank wait.
  Stream<RasterizedPage> rasterize({
    required Uint8List documentBytes,
    required Directory directory,
    required String baseName,
    required PdfTarget target,
    required int dpi,
    required int quality,
  }) async* {
    int pageNumber = 0;

    await for (final PdfRaster raster in Printing.raster(
      documentBytes,
      dpi: dpi.toDouble(),
    )) {
      pageNumber++;

      final Uint8List encoded = await _encode(raster, target, quality);
      final String name = '${baseName}_$pageNumber.${target.extension}';
      final File file = File('${directory.path}${Platform.pathSeparator}$name');

      await file.writeAsBytes(encoded, flush: true);

      yield RasterizedPage(
        name: name,
        path: file.path,
        sizeInBytes: encoded.length,
        pageNumber: pageNumber,
      );
    }
  }

  /// How many pages [documentBytes] holds.
  ///
  /// Counted up front so progress can be a fraction from the first page rather
  /// than a spinner that only learns the total once it is done. Rasterising at
  /// the lowest resolution PDFium accepts makes this cheap.
  Future<int> countPages(Uint8List documentBytes) async {
    int pages = 0;

    await for (final PdfRaster _ in Printing.raster(documentBytes, dpi: 1)) {
      pages++;
    }

    return pages;
  }

  static Future<Uint8List> _encode(
    PdfRaster raster,
    PdfTarget target,
    int quality,
  ) {
    // The pixel buffer of a 300 dpi A4 page is around 35 MB, and encoding it
    // is pure Dart. On the UI isolate that is a visible stall per page.
    final Uint8List pixels = raster.pixels;
    final int width = raster.width;
    final int height = raster.height;

    return Isolate.run(() {
      final img.Image image = img.Image.fromBytes(
        width: width,
        height: height,
        bytes: pixels.buffer,
        numChannels: 4,
      );

      return target == PdfTarget.jpg
          ? img.encodeJpg(image, quality: quality)
          : img.encodePng(image);
    });
  }
}

/// One page written out as a picture.
class RasterizedPage {
  const RasterizedPage({
    required this.name,
    required this.path,
    required this.sizeInBytes,
    required this.pageNumber,
  });

  final String name;
  final String path;
  final int sizeInBytes;
  final int pageNumber;
}
