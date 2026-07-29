import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:archonex_converter/core/constants/app_file_limits.dart';
import 'package:archonex_converter/project_files/features/converter_shared/domain/models/conversion_failure.dart';
import 'package:archonex_converter/project_files/features/converter_shared/domain/models/source_file.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/data/use_cases/pick_pdf_sources_use_case.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/domain/models/pdf_format.dart';

import 'fakes.dart';

void main() {
  late FakePdfFileRepo repo;
  late PickPdfSourcesUseCase pick;

  setUp(() {
    // AppFileLimits reads the platform, so the ceilings have to be pinned.
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    repo = FakePdfFileRepo();
    pick = PickPdfSourcesUseCase(repo);
  });

  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test('a closed dialog is not a failure', () async {
    repo.pickResult = <SourceFile>[];

    final PickedPdfSources picked = await pick();

    expect(picked.accepted, isEmpty);
    expect(picked.rejection, isNull);
  });

  test('takes a batch of one kind', () async {
    repo.pickResult = <SourceFile>[source('a.png'), source('b.jpg')];

    final PickedPdfSources picked = await pick();

    expect(picked.accepted, hasLength(2));
    expect(picked.rejection, isNull);
  });

  test('refuses a batch that mixes kinds, because it has no direction',
      () async {
    repo.pickResult = <SourceFile>[source('a.png'), source('b.pdf')];

    expect(pick(), throwsA(isA<MixedSourceKindsFailure>()));
  });

  test('refuses an addition that would change the direction', () async {
    repo.pickResult = <SourceFile>[source('scan.pdf')];

    expect(
      pick(alreadySelected: 1, existingKind: PdfSourceKind.image),
      throwsA(isA<MixedSourceKindsFailure>()),
    );
  });

  test('allows an addition of the same kind', () async {
    repo.pickResult = <SourceFile>[source('b.jpg')];

    final PickedPdfSources picked = await pick(
      alreadySelected: 1,
      existingKind: PdfSourceKind.image,
    );

    expect(picked.accepted, hasLength(1));
  });

  test('keeps the good files and counts the rest', () async {
    repo.pickResult = <SourceFile>[
      source('a.png'),
      source('notes.docx'),
      source('b.png'),
    ];

    final PickedPdfSources picked = await pick();

    expect(picked.accepted.map((file) => file.name), <String>['a.png', 'b.png']);
    expect(picked.rejection, isA<FilesSkippedFailure>());
  });

  test('throws the real reason when nothing usable came back', () async {
    repo.pickResult = <SourceFile>[source('notes.docx')];

    expect(pick(), throwsA(isA<UnsupportedFormatFailure>()));
  });

  test('refuses an empty file', () async {
    repo.pickResult = <SourceFile>[source('a.png', sizeInBytes: 0)];

    expect(pick(), throwsA(isA<EmptyFileFailure>()));
  });

  test('refuses a file over the ceiling, by one byte', () async {
    repo.pickResult = <SourceFile>[
      source('a.png', sizeInBytes: AppFileLimits.maxUploadBytes + 1),
    ];

    expect(pick(), throwsA(isA<FileTooLargeFailure>()));
  });

  test('takes a file exactly on the ceiling', () async {
    repo.pickResult = <SourceFile>[
      source('a.png', sizeInBytes: AppFileLimits.maxUploadBytes),
    ];

    final PickedPdfSources picked = await pick();

    expect(picked.accepted, hasLength(1));
  });

  test('the batch ceiling counts what is already held', () async {
    repo.pickResult = <SourceFile>[source('a.png')];

    expect(
      pick(alreadySelected: AppFileLimits.maxBatchFiles),
      throwsA(isA<TooManyFilesFailure>()),
    );
  });
}
