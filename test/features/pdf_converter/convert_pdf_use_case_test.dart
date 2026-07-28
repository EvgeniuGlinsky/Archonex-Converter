import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:archonex_converter/core/constants/app_file_limits.dart';
import 'package:archonex_converter/project_files/features/converter_shared/domain/models/conversion_failure.dart';
import 'package:archonex_converter/project_files/features/converter_shared/domain/models/source_file.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/data/use_cases/convert_pdf_use_case.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/domain/models/pdf_conversion_settings.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/domain/models/pdf_page_size.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/domain/models/pdf_target.dart';

import 'fakes.dart';

void main() {
  late FakePdfConverterRepo repo;
  late ConvertPdfUseCase convert;

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    repo = FakePdfConverterRepo();
    convert = ConvertPdfUseCase(repo);
  });

  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test('starts a run for a well formed request', () {
    convert(
      sources: <SourceFile>[source('a.png'), source('b.png')],
      target: PdfTarget.pdf,
      settings: const PdfConversionSettings(),
    );

    expect(repo.convertCallCount, 1);
    expect(repo.lastTarget, PdfTarget.pdf);
  });

  test('refuses an empty request', () {
    expect(
      () => convert(
        sources: const <SourceFile>[],
        target: PdfTarget.pdf,
        settings: const PdfConversionSettings(),
      ),
      throwsA(isA<FileReadFailure>()),
    );
  });

  test('refuses a format it cannot read', () {
    expect(
      () => convert(
        sources: <SourceFile>[source('notes.docx')],
        target: PdfTarget.pdf,
        settings: const PdfConversionSettings(),
      ),
      throwsA(isA<UnsupportedFormatFailure>()),
    );
  });

  test('refuses a mixed batch even if the screen let one through', () {
    expect(
      () => convert(
        sources: <SourceFile>[source('a.png'), source('b.pdf')],
        target: PdfTarget.pdf,
        settings: const PdfConversionSettings(),
      ),
      throwsA(isA<MixedSourceKindsFailure>()),
    );
  });

  test('refuses a target the direction cannot reach', () {
    expect(
      () => convert(
        // Pictures can only become a PDF, never another picture: that is what
        // the image converter is for.
        sources: <SourceFile>[source('a.png')],
        target: PdfTarget.jpg,
        settings: const PdfConversionSettings(),
      ),
      throwsA(isA<IncompatibleTargetFailure>()),
    );
  });

  test('refuses a source over the ceiling', () {
    expect(
      () => convert(
        sources: <SourceFile>[
          source('a.png', sizeInBytes: AppFileLimits.maxUploadBytes + 1),
        ],
        target: PdfTarget.pdf,
        settings: const PdfConversionSettings(),
      ),
      throwsA(isA<FileTooLargeFailure>()),
    );
  });

  test('prunes the settings before handing them to the engine', () {
    convert(
      sources: <SourceFile>[source('a.png')],
      target: PdfTarget.pdf,
      settings: const PdfConversionSettings(
        pageSize: PdfPageSize.a4,
        rasterDpi: 600,
      ),
    );

    // Resolution means nothing when writing a PDF, so the engine must not see
    // a value that would look deliberate.
    expect(
      repo.lastSettings?.rasterDpi,
      PdfConversionSettings.defaultRasterDpi,
    );
    expect(repo.lastSettings?.pageSize, PdfPageSize.a4);
  });
}
