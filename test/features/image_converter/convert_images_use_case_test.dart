import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:archonex_converter/core/constants/app_file_limits.dart';
import 'package:archonex_converter/project_files/features/converter_shared/domain/models/conversion_failure.dart';
import 'package:archonex_converter/project_files/features/converter_shared/domain/models/source_file.dart';
import 'package:archonex_converter/project_files/features/image_converter/data/use_cases/convert_images_use_case.dart';
import 'package:archonex_converter/project_files/features/image_converter/domain/models/image_conversion_settings.dart';
import 'package:archonex_converter/project_files/features/image_converter/domain/models/image_dimension_limit.dart';
import 'package:archonex_converter/project_files/features/image_converter/domain/models/image_format.dart';

import 'fakes.dart';

void main() {
  late FakeImageConverterRepo repo;
  late ConvertImagesUseCase convertImages;

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    repo = FakeImageConverterRepo();
    convertImages = ConvertImagesUseCase(repo);
  });

  tearDown(() => debugDefaultTargetPlatformOverride = null);

  SourceFile photo(String name, {int sizeInBytes = 1024}) => SourceFile(
        name: name,
        sizeInBytes: sizeInBytes,
        path: '/tmp/$name',
      );

  test('hands the whole batch and the settings to the engine untouched', () {
    const ImageConversionSettings settings = ImageConversionSettings(
      dimensionLimit: ImageDimensionLimit.px1280,
      keepMetadata: true,
    );
    final List<SourceFile> sources = <SourceFile>[
      photo('a.png'),
      photo('b.png'),
    ];

    convertImages(
      sources: sources,
      target: ImageFormat.webp,
      settings: settings,
    );

    expect(repo.convertCallCount, 1);
    expect(repo.lastSources, sources);
    expect(repo.lastTarget, ImageFormat.webp);
    expect(repo.lastSettings, settings);
  });

  test('refuses a source whose format it does not know', () {
    expect(
      () => convertImages(
        sources: <SourceFile>[photo('a.png'), photo('art.psd')],
        target: ImageFormat.webp,
        settings: const ImageConversionSettings(),
      ),
      throwsA(isA<UnsupportedFormatFailure>()),
    );
    expect(repo.convertCallCount, 0);
  });

  test('refuses converting a format into itself', () {
    expect(
      () => convertImages(
        sources: <SourceFile>[photo('a.png')],
        target: ImageFormat.png,
        settings: const ImageConversionSettings(),
      ),
      throwsA(
        isA<IncompatibleTargetFailure>()
            .having((failure) => failure.sourceLabel, 'sourceLabel', 'PNG')
            .having((failure) => failure.targetLabel, 'targetLabel', 'PNG'),
      ),
    );
  });

  test('refuses a target nothing can write', () {
    expect(
      () => convertImages(
        sources: <SourceFile>[photo('a.png')],
        target: ImageFormat.heic,
        settings: const ImageConversionSettings(),
      ),
      throwsA(isA<IncompatibleTargetFailure>()),
    );
  });

  test('re-checks the per file ceiling the pick already applied', () {
    expect(
      () => convertImages(
        sources: <SourceFile>[
          photo('a.png'),
          photo('huge.png', sizeInBytes: AppFileLimits.maxUploadBytes + 1),
        ],
        target: ImageFormat.webp,
        settings: const ImageConversionSettings(),
      ),
      throwsA(isA<FileTooLargeFailure>()),
    );
    expect(repo.convertCallCount, 0);
  });

  test('re-checks the batch ceiling the pick already applied', () {
    expect(
      () => convertImages(
        sources: <SourceFile>[
          for (int i = 0; i <= AppFileLimits.maxBatchFiles; i++) photo('$i.png'),
        ],
        target: ImageFormat.webp,
        settings: const ImageConversionSettings(),
      ),
      throwsA(isA<TooManyFilesFailure>()),
    );
    expect(repo.convertCallCount, 0);
  });

  test('a mixed batch is fine as long as every source can reach the target',
      () {
    convertImages(
      sources: <SourceFile>[photo('a.png'), photo('b.heic'), photo('c.webp')],
      target: ImageFormat.jpg,
      settings: const ImageConversionSettings(),
    );

    expect(repo.convertCallCount, 1);
  });
}
