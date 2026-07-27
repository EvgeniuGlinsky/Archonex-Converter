import 'package:flutter_test/flutter_test.dart';

import 'package:archonex_converter/core/constants/app_file_limits.dart';
import 'package:archonex_converter/project_files/features/converter_shared/domain/models/conversion_failure.dart';
import 'package:archonex_converter/project_files/features/converter_shared/domain/models/source_file.dart';
import 'package:archonex_converter/project_files/features/media_converter/data/use_cases/pick_source_file_use_case.dart';
import 'package:archonex_converter/project_files/features/media_converter/domain/models/media_format.dart';

import 'fakes.dart';

void main() {
  late FakeMediaFileRepo repo;
  late PickSourceFileUseCase pickSourceFile;

  setUp(() {
    repo = FakeMediaFileRepo();
    pickSourceFile = PickSourceFileUseCase(repo);
  });

  test('returns null when the dialog was closed without a choice', () async {
    expect(await pickSourceFile(), isNull);
  });

  test('accepts a file of any format the converter knows', () async {
    for (final MediaFormat format in MediaFormat.values) {
      repo.pickResult = SourceFile(
        name: 'clip.${format.extension}',
        sizeInBytes: 1024,
      );

      final SourceFile? file = await pickSourceFile();

      expect(
        MediaFormat.fromExtension(file?.extension ?? ''),
        format,
        reason: '${format.extension} was refused',
      );
    }
  });

  test('resolves the format whatever the case of the extension', () async {
    repo.pickResult = const SourceFile(name: 'CLIP.MOV', sizeInBytes: 1024);

    final SourceFile? file = await pickSourceFile();

    expect(MediaFormat.fromExtension(file?.extension ?? ''), MediaFormat.mov);
  });

  test('refuses an extension it does not know', () async {
    repo.pickResult = const SourceFile(name: 'art.psd', sizeInBytes: 1024);

    await expectLater(
      pickSourceFile(),
      throwsA(
        isA<UnsupportedFormatFailure>().having(
          (failure) => failure.actualExtension,
          'actualExtension',
          'psd',
        ),
      ),
    );
  });

  test('refuses a file with no extension at all', () async {
    repo.pickResult = const SourceFile(name: 'clip', sizeInBytes: 1024);

    await expectLater(
      pickSourceFile(),
      throwsA(
        isA<UnsupportedFormatFailure>().having(
          (failure) => failure.actualExtension,
          'actualExtension',
          isEmpty,
        ),
      ),
    );
  });

  test('refuses an empty file', () async {
    repo.pickResult = const SourceFile(name: 'clip.mp4', sizeInBytes: 0);

    await expectLater(pickSourceFile(), throwsA(isA<EmptyFileFailure>()));
  });

  test('accepts a file of exactly the maximum size', () async {
    repo.pickResult = SourceFile(
      name: 'clip.mp4',
      sizeInBytes: AppFileLimits.maxUploadBytes,
    );

    expect(await pickSourceFile(), isNotNull);
  });

  test('refuses a file one byte over the maximum', () async {
    repo.pickResult = SourceFile(
      name: 'clip.mp4',
      sizeInBytes: AppFileLimits.maxUploadBytes + 1,
    );

    await expectLater(pickSourceFile(), throwsA(isA<FileTooLargeFailure>()));
  });

  test('lets a picker failure through untouched', () async {
    repo.pickError = const FileReadFailure();

    await expectLater(pickSourceFile(), throwsA(isA<FileReadFailure>()));
  });
}
