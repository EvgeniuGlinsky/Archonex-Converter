import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:archonex_converter/project_files/features/pdf_converter/data/engine/pdf_write_request.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/domain/models/pdf_conversion_settings.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/domain/models/pdf_format.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/domain/models/pdf_page_size.dart';

/// Builds a PDF out of pictures or text.
///
/// The entry point runs on a background isolate: assembling thirty full size
/// photos is seconds of pure Dart work, and on the UI isolate that is a frozen
/// screen rather than a slow one. Everything here is therefore plain Dart with
/// no Flutter bindings — the font arrives as bytes for exactly that reason.
class PdfDocumentWriter {
  const PdfDocumentWriter._();

  /// How many source characters to name back when the font cannot draw them.
  static const int _sampleLength = 8;

  /// Isolate entry point. Reports progress and the outcome over
  /// [PdfWriteRequest.replyPort]; never throws across the port.
  static Future<void> run(PdfWriteRequest request) async {
    try {
      final pw.Document document = pw.Document();
      final pw.Font font = pw.Font.ttf(
        ByteData.view(Uint8List.fromList(request.fontBytes).buffer),
      );

      switch (request.kind) {
        case PdfSourceKind.image:
          await _addImagePages(document, request);
        case PdfSourceKind.text:
          await _addTextPages(document, request, font);
        case PdfSourceKind.pdf:
          // Never reached: a PDF source is rasterised, not written.
          request.replyPort.send(const PdfWriteFailed(PdfWriteError.engine));

          return;
      }

      final Uint8List bytes = await document.save();
      final File output = File(request.outputPath);
      await output.writeAsBytes(bytes, flush: true);

      request.replyPort.send(PdfWriteDone(sizeInBytes: bytes.length));
    } on _UnsupportedCharacters catch (failure) {
      request.replyPort.send(
        PdfWriteFailed(
          PdfWriteError.unsupportedCharacters,
          detail: failure.sample,
        ),
      );
    } on FileSystemException {
      request.replyPort.send(
        const PdfWriteFailed(PdfWriteError.unreadableSource),
      );
    } catch (_) {
      request.replyPort.send(const PdfWriteFailed(PdfWriteError.engine));
    }
  }

  static Future<void> _addImagePages(
    pw.Document document,
    PdfWriteRequest request,
  ) async {
    final int total = request.sourcePaths.length;

    for (int index = 0; index < total; index++) {
      final Uint8List bytes =
          await File(request.sourcePaths[index]).readAsBytes();
      final pw.MemoryImage image = pw.MemoryImage(bytes);

      document.addPage(
        pw.Page(
          pageFormat: _pageFormatFor(request.settings, image),
          margin: pw.EdgeInsets.all(request.settings.marginPoints),
          build: (context) => pw.Center(
            child: pw.Image(image, fit: pw.BoxFit.contain),
          ),
        ),
      );

      request.replyPort.send(PdfWriteProgress(done: index + 1, total: total));
    }
  }

  /// One document from every text file, with each file starting a fresh page so
  /// a merged batch does not read as one run-on wall of text.
  static Future<void> _addTextPages(
    pw.Document document,
    PdfWriteRequest request,
    pw.Font font,
  ) async {
    final int total = request.sourcePaths.length;
    final Set<int> drawable = _drawableRunes(request.fontBytes);

    for (int index = 0; index < total; index++) {
      final String text = await File(request.sourcePaths[index])
          .readAsString(encoding: utf8);

      _refuseUndrawable(text, drawable);

      document.addPage(
        pw.MultiPage(
          pageFormat: _textPageFormat(request.settings),
          margin: pw.EdgeInsets.all(request.settings.marginPoints),
          build: (context) => <pw.Widget>[
            pw.Paragraph(
              text: text,
              style: pw.TextStyle(font: font, fontSize: _bodyFontSize),
            ),
          ],
        ),
      );

      request.replyPort.send(PdfWriteProgress(done: index + 1, total: total));
    }
  }

  static const double _bodyFontSize = 11;

  /// Every code point the embedded font has a glyph for.
  ///
  /// Read off the font's own character map rather than guessed at from Unicode
  /// blocks, so the answer cannot drift if the bundled font is ever swapped.
  static Set<int> _drawableRunes(List<int> fontBytes) {
    final TtfParser parser = TtfParser(
      ByteData.view(Uint8List.fromList(fontBytes).buffer),
    );

    return parser.charToGlyphIndexMap.keys.toSet();
  }

  /// Throws when [text] needs a glyph the font does not carry.
  ///
  /// The PDF writer would otherwise produce a perfectly valid document full of
  /// blank boxes, which is worse than refusing: it looks like it worked.
  static void _refuseUndrawable(String text, Set<int> drawable) {
    final StringBuffer missing = StringBuffer();
    final Set<int> seen = <int>{};

    for (final int rune in text.runes) {
      if (_isWhitespace(rune) || drawable.contains(rune) || !seen.add(rune)) {
        continue;
      }

      missing.writeCharCode(rune);

      if (seen.length >= _sampleLength && missing.length >= _sampleLength) {
        break;
      }
    }

    if (missing.isNotEmpty) {
      throw _UnsupportedCharacters(missing.toString());
    }
  }

  static bool _isWhitespace(int rune) =>
      rune == 0x20 || rune == 0x09 || rune == 0x0A || rune == 0x0D;

  /// Page geometry for a picture. [PdfPageSize.fitSource] maps the picture's
  /// pixels onto points one for one, which keeps its proportions exactly and
  /// leaves no bars around it.
  static PdfPageFormat _pageFormatFor(
    PdfConversionSettings settings,
    pw.MemoryImage image,
  ) {
    if (!settings.pageSize.followsSource) {
      return _fixedFormat(settings.pageSize);
    }

    final int? width = image.width;
    final int? height = image.height;

    // Dimensions are only known once the picture decoded. A format the decoder
    // could not measure still belongs in the document, so it goes on a normal
    // page rather than failing the whole batch.
    if (width == null || height == null) {
      return PdfPageFormat.a4;
    }

    final double margin = settings.marginPoints * 2;

    return PdfPageFormat(width + margin, height + margin);
  }

  /// Text has no intrinsic size, so [PdfPageSize.fitSource] falls back to A4.
  static PdfPageFormat _textPageFormat(PdfConversionSettings settings) =>
      settings.pageSize.followsSource
          ? PdfPageFormat.a4
          : _fixedFormat(settings.pageSize);

  static PdfPageFormat _fixedFormat(PdfPageSize size) => PdfPageFormat(
        size.widthPoints!,
        size.heightPoints!,
      );
}

/// Internal signal from the page builders up to [PdfDocumentWriter.run].
class _UnsupportedCharacters implements Exception {
  const _UnsupportedCharacters(this.sample);

  final String sample;
}
