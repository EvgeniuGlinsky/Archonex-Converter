import 'package:flutter_test/flutter_test.dart';

import 'package:archonex_converter/core/constants/app_file_limits.dart';
import 'package:archonex_converter/project_files/features/converter_shared/domain/models/conversion_failure.dart';
import 'package:archonex_converter/project_files/features/converter_shared/domain/models/source_file.dart';
import 'package:archonex_converter/project_files/features/media_converter/data/use_cases/convert_media_use_case.dart';
import 'package:archonex_converter/project_files/features/media_converter/domain/models/conversion_settings.dart';
import 'package:archonex_converter/project_files/features/media_converter/domain/models/media_format.dart';

import 'fakes.dart';

void main() {
  late FakeMediaConverterRepo repo;
  late ConvertMediaUseCase convertMedia;

  const SourceFile clip = SourceFile(
    name: 'clip.mp4',
    sizeInBytes: 5 * 1024 * 1024,
    path: '/tmp/clip.mp4',
  );

  setUp(() {
    repo = FakeMediaConverterRepo();
    convertMedia = ConvertMediaUseCase(repo);
  });

  test('starts the engine for a reachable target', () {
    convertMedia(
      source: clip,
      target: MediaFormat.webm,
      settings: const ConversionSettings(),
    );

    expect(repo.convertCallCount, 1);
    expect(repo.lastTarget, MediaFormat.webm);
  });

  test('refuses a target the source cannot reach', () {
    const SourceFile song = SourceFile(name: 'song.mp3', sizeInBytes: 1024);

    expect(
      () => convertMedia(
        source: song,
        target: MediaFormat.mp4,
        settings: const ConversionSettings(),
      ),
      throwsA(isA<IncompatibleTargetFailure>()),
    );
    expect(repo.convertCallCount, 0);
  });

  test('refuses a source whose format is not recognised', () {
    const SourceFile art = SourceFile(name: 'art.psd', sizeInBytes: 1024);

    expect(
      () => convertMedia(
        source: art,
        target: MediaFormat.mp4,
        settings: const ConversionSettings(),
      ),
      throwsA(isA<UnsupportedFormatFailure>()),
    );
    expect(repo.convertCallCount, 0);
  });

  test('re-checks the upload ceiling before touching the engine', () {
    final SourceFile huge = SourceFile(
      name: 'huge.mp4',
      sizeInBytes: AppFileLimits.maxUploadBytes + 1,
    );

    expect(
      () => convertMedia(
        source: huge,
        target: MediaFormat.gif,
        settings: const ConversionSettings(),
      ),
      throwsA(isA<FileTooLargeFailure>()),
    );
    expect(repo.convertCallCount, 0);
  });

  test('hands the settings through unchanged', () {
    const ConversionSettings settings = ConversionSettings(videoQuality: 90);

    convertMedia(
      source: clip,
      target: MediaFormat.mkv,
      settings: settings,
    );

    expect(repo.lastSettings, settings);
  });
}
