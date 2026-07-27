// Exercises the real PDF engine, which the unit tests cannot: they run against
// fakes, so nothing there touches the `pdf` writer, the bundled font, the
// background isolate, or PDFium behind `Printing.raster`.
//
// Not part of CI — it needs a real device or desktop runner:
//
//   flutter test integration_test/pdf_engine_probe_test.dart -d windows
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:archonex_converter/project_files/features/converter_shared/domain/models/conversion_failure.dart';
import 'package:archonex_converter/project_files/features/converter_shared/domain/models/converted_file.dart';
import 'package:archonex_converter/project_files/features/converter_shared/domain/models/source_file.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/data/engine/dart_pdf_converter_repo.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/domain/models/pdf_conversion_settings.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/domain/models/pdf_conversion_update.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/domain/models/pdf_target.dart';

/// Smallest valid PNG: one opaque pixel.
final Uint8List _onePixelPng = Uint8List.fromList(<int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, //
  0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53,
  0xDE, 0x00, 0x00, 0x00, 0x0C, 0x49, 0x44, 0x41,
  0x54, 0x08, 0xD7, 0x63, 0xF8, 0xCF, 0xC0, 0x00,
  0x00, 0x03, 0x01, 0x01, 0x00, 0x18, 0xDD, 0x8D,
  0xB0, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E,
  0x44, 0xAE, 0x42, 0x60, 0x82,
]);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const DartPdfConverterRepo repo = DartPdfConverterRepo();
  late Directory workspace;

  setUp(() async {
    workspace = await Directory.systemTemp.createTemp('archonex_pdf_probe_');
  });

  tearDown(() async {
    if (workspace.existsSync()) {
      await workspace.delete(recursive: true);
    }
  });

  Future<SourceFile> writeSource(String name, List<int> bytes) async {
    final File file = File('${workspace.path}${Platform.pathSeparator}$name');
    await file.writeAsBytes(bytes, flush: true);

    return SourceFile(
      name: name,
      sizeInBytes: bytes.length,
      path: file.path,
    );
  }

  /// Drains a run and hands back what it produced.
  Future<List<ConvertedFile>> run({
    required List<SourceFile> sources,
    required PdfTarget target,
    PdfConversionSettings settings = const PdfConversionSettings(),
  }) async {
    final List<ConvertedFile> produced = <ConvertedFile>[];
    int lastTotal = 0;

    await for (final PdfConversionUpdate update in repo
        .convert(sources: sources, target: target, settings: settings)
        .updates) {
      switch (update) {
        case PdfFileProduced(:final ConvertedFile file):
          produced.add(file);
        case PdfProgressed(:final int total):
          lastTotal = total;
      }
    }

    expect(lastTotal, greaterThan(0), reason: 'progress never reported a total');

    return produced;
  }

  testWidgets('images become one PDF', (WidgetTester tester) async {
    final List<SourceFile> sources = <SourceFile>[
      await writeSource('a.png', _onePixelPng),
      await writeSource('b.png', _onePixelPng),
    ];

    final List<ConvertedFile> produced =
        await run(sources: sources, target: PdfTarget.pdf);

    expect(produced, hasLength(1), reason: 'a merged run yields one document');

    final File output = File(produced.single.path);
    expect(output.existsSync(), isTrue);

    final Uint8List bytes = await output.readAsBytes();
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');

    await repo.discard(produced);
    expect(output.existsSync(), isFalse, reason: 'discard must clean up');
  });

  testWidgets('cyrillic text is written, not silently blanked',
      (WidgetTester tester) async {
    // utf8.encode, not codeUnits: the writer reads the file back as UTF-8, and
    // UTF-16 code units written as raw bytes would arrive as mojibake.
    final SourceFile source = await writeSource(
      'notes.txt',
      utf8.encode('Привет мир — Hello world'),
    );

    final List<ConvertedFile> produced =
        await run(sources: <SourceFile>[source], target: PdfTarget.pdf);

    expect(produced, hasLength(1));
    await repo.discard(produced);
  });

  testWidgets('CJK is refused instead of coming out as blank boxes',
      (WidgetTester tester) async {
    final SourceFile source = await writeSource(
      'chinese.txt',
      utf8.encode('你好世界'),
    );

    await expectLater(
      run(sources: <SourceFile>[source], target: PdfTarget.pdf),
      throwsA(isA<UnsupportedCharactersFailure>()),
    );
  });

  testWidgets('a PDF comes back out as one image per page',
      (WidgetTester tester) async {
    // Build a two page document first, then read it back.
    final List<SourceFile> images = <SourceFile>[
      await writeSource('p1.png', _onePixelPng),
      await writeSource('p2.png', _onePixelPng),
    ];

    final List<ConvertedFile> document =
        await run(sources: images, target: PdfTarget.pdf);

    final File pdf = File(document.single.path);
    final SourceFile asSource = SourceFile(
      name: document.single.name,
      sizeInBytes: document.single.sizeInBytes,
      path: pdf.path,
    );

    final List<ConvertedFile> pages =
        await run(sources: <SourceFile>[asSource], target: PdfTarget.png);

    expect(pages, hasLength(2), reason: 'one file per page');
    for (final ConvertedFile page in pages) {
      expect(File(page.path).existsSync(), isTrue);
      expect(page.sizeInBytes, greaterThan(0));
    }

    await repo.discard(document);
    await repo.discard(pages);
  });
}
