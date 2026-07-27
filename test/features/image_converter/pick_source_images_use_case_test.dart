import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:archonex_converter/core/constants/app_file_limits.dart';
import 'package:archonex_converter/project_files/features/converter_shared/domain/models/conversion_failure.dart';
import 'package:archonex_converter/project_files/features/converter_shared/domain/models/source_file.dart';
import 'package:archonex_converter/project_files/features/image_converter/data/use_cases/pick_source_images_use_case.dart';

import 'fakes.dart';

void main() {
  late FakeImageFileRepo repo;
  late PickSourceImagesUseCase pickSourceImages;

  setUp(() {
    // Pinned so the ceilings under test are the same on every machine.
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    repo = FakeImageFileRepo();
    pickSourceImages = PickSourceImagesUseCase(repo);
  });

  tearDown(() => debugDefaultTargetPlatformOverride = null);

  SourceFile photo(String name, {int? sizeInBytes}) => SourceFile(
        name: name,
        sizeInBytes: sizeInBytes ?? 1024,
        path: '/tmp/$name',
      );

  test('an empty pick is a closed dialog, not a failure', () async {
    final PickedImages picked = await pickSourceImages();

    expect(picked.accepted, isEmpty);
    expect(picked.rejection, isNull);
  });

  test('accepts every format the converter reads', () async {
    repo.pickResult = <SourceFile>[
      photo('a.jpg'),
      photo('b.jpeg'),
      photo('c.png'),
      photo('d.webp'),
      photo('e.heic'),
      photo('f.tif'),
    ];

    final PickedImages picked = await pickSourceImages();

    expect(picked.accepted, hasLength(6));
    expect(picked.rejection, isNull);
  });

  group('the per file ceiling', () {
    test('accepts a file of exactly the maximum size', () async {
      repo.pickResult = <SourceFile>[
        photo('big.jpg', sizeInBytes: AppFileLimits.maxUploadBytes),
      ];

      expect((await pickSourceImages()).accepted, hasLength(1));
    });

    test('refuses a file one byte over the maximum', () async {
      repo.pickResult = <SourceFile>[
        photo('big.jpg', sizeInBytes: AppFileLimits.maxUploadBytes + 1),
      ];

      await expectLater(
        pickSourceImages(),
        throwsA(
          isA<FileTooLargeFailure>().having(
            (failure) => failure.limitBytes,
            'limitBytes',
            AppFileLimits.maxUploadBytes,
          ),
        ),
      );
    });

    test('refuses an empty file', () async {
      repo.pickResult = <SourceFile>[photo('empty.png', sizeInBytes: 0)];

      await expectLater(
        pickSourceImages(),
        throwsA(isA<EmptyFileFailure>()),
      );
    });

    test('refuses an extension it does not know', () async {
      repo.pickResult = <SourceFile>[photo('art.psd')];

      await expectLater(
        pickSourceImages(),
        throwsA(
          isA<UnsupportedFormatFailure>().having(
            (failure) => failure.actualExtension,
            'actualExtension',
            'psd',
          ),
        ),
      );
    });
  });

  group('the batch ceiling', () {
    test('accepts exactly the maximum number of files', () async {
      repo.pickResult = <SourceFile>[
        for (int i = 0; i < AppFileLimits.maxBatchFiles; i++) photo('$i.jpg'),
      ];

      expect(
        (await pickSourceImages()).accepted,
        hasLength(AppFileLimits.maxBatchFiles),
      );
    });

    test('refuses one file over the maximum', () async {
      repo.pickResult = <SourceFile>[
        for (int i = 0; i <= AppFileLimits.maxBatchFiles; i++) photo('$i.jpg'),
      ];

      await expectLater(
        pickSourceImages(),
        throwsA(
          isA<TooManyFilesFailure>().having(
            (failure) => failure.limitCount,
            'limitCount',
            AppFileLimits.maxBatchFiles,
          ),
        ),
      );
    });

    test('counts what is already on screen towards the ceiling', () async {
      repo.pickResult = <SourceFile>[photo('one-more.jpg')];

      await expectLater(
        pickSourceImages(alreadySelected: AppFileLimits.maxBatchFiles),
        throwsA(isA<TooManyFilesFailure>()),
      );
    });
  });

  group('a mixed pick', () {
    test('keeps the good files and reports how many were dropped', () async {
      repo.pickResult = <SourceFile>[
        photo('good.jpg'),
        photo('art.psd'),
        photo('huge.png', sizeInBytes: AppFileLimits.maxUploadBytes + 1),
        photo('also-good.png'),
      ];

      final PickedImages picked = await pickSourceImages();

      expect(
        picked.accepted.map((file) => file.name),
        <String>['good.jpg', 'also-good.png'],
      );
      expect(
        picked.rejection,
        isA<FilesSkippedFailure>().having(
          (failure) => failure.skippedCount,
          'skippedCount',
          2,
        ),
      );
    });

    test('throws the first real reason when nothing is usable', () async {
      // A vague "some files were skipped" would be useless when the answer is
      // "none of them were photos".
      repo.pickResult = <SourceFile>[photo('a.psd'), photo('b.doc')];

      await expectLater(
        pickSourceImages(),
        throwsA(isA<UnsupportedFormatFailure>()),
      );
    });

    test('nothing is reported when the whole pick was usable', () async {
      repo.pickResult = <SourceFile>[photo('a.jpg'), photo('b.png')];

      expect((await pickSourceImages()).rejection, isNull);
    });
  });
}
