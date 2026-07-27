import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:archonex/core/constants/app_file_limits.dart';
import 'package:archonex/project_files/features/converter_shared/domain/models/conversion_failure.dart';
import 'package:archonex/project_files/features/converter_shared/domain/models/converted_file.dart';
import 'package:archonex/project_files/features/converter_shared/domain/models/save_result.dart';
import 'package:archonex/project_files/features/media_converter/data/use_cases/save_converted_file_use_case.dart';

import 'fakes.dart';

void main() {
  late FakeMediaFileRepo repo;
  late SaveConvertedFileUseCase saveConvertedFile;

  setUp(() {
    repo = FakeMediaFileRepo();
    saveConvertedFile = SaveConvertedFileUseCase(repo);
  });

  tearDown(() => debugDefaultTargetPlatformOverride = null);

  ConvertedFile resultOf(int bytes) => ConvertedFile(
        name: 'clip.wav',
        path: '/tmp/archonex_convert_test/clip.wav',
        sizeInBytes: bytes,
      );

  test('saves a result inside the ceiling', () async {
    repo.saveLocation = r'C:\Users\me\clip.wav';

    final SaveResult result = await saveConvertedFile(resultOf(1024));

    expect(result.outcome, SaveOutcome.savedToLocation);
    expect(repo.saveCallCount, 1);
  });

  test('accepts a result of exactly the ceiling', () async {
    repo.saveLocation = r'C:\Users\me\clip.wav';

    await saveConvertedFile(resultOf(AppFileLimits.maxResultBytes));

    expect(repo.saveCallCount, 1);
  });

  test('refuses a result one byte over, without touching the platform',
      () async {
    // An output can be larger than the input it came from — a compact MP4
    // turned into WAV, say — so the input check does not cover this.
    await expectLater(
      saveConvertedFile(resultOf(AppFileLimits.maxResultBytes + 1)),
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

  test('the ceiling it enforces follows the platform', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final int androidCeiling = AppFileLimits.maxResultBytes;

    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    final int desktopCeiling = AppFileLimits.maxResultBytes;

    expect(desktopCeiling, greaterThan(androidCeiling));

    // A result that desktop saves happily is refused on a phone, which is the
    // whole point of the ceiling being per platform.
    repo.saveLocation = r'C:\Users\me\clip.wav';
    await saveConvertedFile(resultOf(androidCeiling + 1));
    expect(repo.saveCallCount, 1);

    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    await expectLater(
      saveConvertedFile(resultOf(androidCeiling + 1)),
      throwsA(isA<ResultTooLargeToSaveFailure>()),
    );
  });
}
