import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:archonex_converter/core/constants/app_file_limits.dart';
import 'package:archonex_converter/project_files/features/converter_shared/domain/models/conversion_failure.dart';
import 'package:archonex_converter/project_files/features/converter_shared/domain/models/converted_file.dart';
import 'package:archonex_converter/project_files/features/converter_shared/domain/models/save_result.dart';
import 'package:archonex_converter/project_files/features/image_converter/data/use_cases/save_all_converted_images_use_case.dart';
import 'package:archonex_converter/project_files/features/image_converter/data/use_cases/save_converted_image_use_case.dart';

import 'fakes.dart';

void main() {
  late FakeImageFileRepo repo;
  late SaveConvertedImageUseCase saveOne;
  late SaveAllConvertedImagesUseCase saveAll;

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    repo = FakeImageFileRepo();
    saveOne = SaveConvertedImageUseCase(repo);
    saveAll = SaveAllConvertedImagesUseCase(repo);
  });

  tearDown(() => debugDefaultTargetPlatformOverride = null);

  ConvertedFile result(String name, {int sizeInBytes = 2048}) => ConvertedFile(
        name: name,
        path: '/tmp/out/$name',
        sizeInBytes: sizeInBytes,
      );

  group('saving one', () {
    test('reports where the file landed', () async {
      repo.saveLocation = '/pictures/a.webp';

      final SaveResult saved = await saveOne(result('a.webp'));

      expect(saved.outcome, SaveOutcome.savedToLocation);
      expect(saved.location, '/pictures/a.webp');
      expect(saved.savedCount, 1);
    });

    test('a closed dialog is a cancellation, not a failure', () async {
      repo.saveLocation = null;

      final SaveResult saved = await saveOne(result('a.webp'));

      expect(saved.outcome, SaveOutcome.cancelled);
      expect(saved.savedCount, 0);
    });

    test('no location on a platform that never reports one is a download',
        () async {
      repo
        ..saveLocation = null
        ..reportsSaveLocation = false;

      final SaveResult saved = await saveOne(result('a.webp'));

      expect(saved.outcome, SaveOutcome.downloadStarted);
    });

    test('refuses a result over the ceiling before touching the platform',
        () async {
      // An output can come out larger than the input it was made from.
      await expectLater(
        saveOne(
          result('huge.tiff', sizeInBytes: AppFileLimits.maxResultBytes + 1),
        ),
        throwsA(
          isA<ResultTooLargeToSaveFailure>().having(
            (failure) => failure.actualBytes,
            'actualBytes',
            AppFileLimits.maxResultBytes + 1,
          ),
        ),
      );
      expect(repo.saveCallCount, 0);
    });
  });

  group('saving the batch', () {
    test('hands every result over in one call', () async {
      final List<ConvertedFile> files = <ConvertedFile>[
        result('a.webp'),
        result('b.webp'),
        result('c.webp'),
      ];

      final SaveResult saved = await saveAll(files);

      expect(repo.saveAllCallCount, 1);
      expect(repo.lastSavedAll, files);
      expect(saved.outcome, SaveOutcome.savedToLocation);
      expect(saved.savedCount, 3);
    });

    test('an empty batch asks the platform for nothing', () async {
      final SaveResult saved = await saveAll(const <ConvertedFile>[]);

      expect(saved.outcome, SaveOutcome.cancelled);
      expect(repo.saveAllCallCount, 0);
    });

    test('the ceiling applies per file, not to the sum', () async {
      // Files leave one at a time, so what has to fit is the largest of them.
      final int half = AppFileLimits.maxResultBytes ~/ 2;

      await saveAll(<ConvertedFile>[
        result('a.webp', sizeInBytes: half),
        result('b.webp', sizeInBytes: half),
        result('c.webp', sizeInBytes: half),
      ]);

      expect(repo.saveAllCallCount, 1);
    });

    test('one oversized result stops the whole batch', () async {
      await expectLater(
        saveAll(<ConvertedFile>[
          result('a.webp'),
          result('huge.tiff', sizeInBytes: AppFileLimits.maxResultBytes + 1),
        ]),
        throwsA(isA<ResultTooLargeToSaveFailure>()),
      );
      expect(repo.saveAllCallCount, 0);
    });

    test('a cancelled destination pick comes back as a cancellation', () async {
      repo.saveAllResult = const SaveResult.cancelled();

      final SaveResult saved = await saveAll(<ConvertedFile>[result('a.webp')]);

      expect(saved.outcome, SaveOutcome.cancelled);
      expect(saved.savedCount, 0);
    });

    test('a partial fallback run reports how many actually landed', () async {
      // The folder route was unavailable and the user closed the third dialog.
      repo.saveAllResult = const SaveResult(
        outcome: SaveOutcome.savedToLocation,
        location: '/pictures',
        savedCount: 2,
      );

      final SaveResult saved = await saveAll(<ConvertedFile>[
        result('a.webp'),
        result('b.webp'),
        result('c.webp'),
      ]);

      expect(saved.savedCount, 2);
    });
  });
}
