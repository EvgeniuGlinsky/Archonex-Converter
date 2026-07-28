import 'package:flutter_test/flutter_test.dart';

import 'package:archonex_converter/project_files/features/converter_shared/data/ffmpeg/ffmpeg_filters.dart';
import 'package:archonex_converter/project_files/features/image_converter/data/ffmpeg/ffmpeg_image_command_builder.dart';
import 'package:archonex_converter/project_files/features/image_converter/domain/models/image_background.dart';
import 'package:archonex_converter/project_files/features/image_converter/domain/models/image_conversion_settings.dart';
import 'package:archonex_converter/project_files/features/image_converter/domain/models/image_dimension_limit.dart';
import 'package:archonex_converter/project_files/features/image_converter/domain/models/image_format.dart';
import 'package:archonex_converter/project_files/features/image_converter/domain/models/image_quality.dart';

void main() {
  const String input = '/tmp/holiday photo.png';
  const String output = '/tmp/out/holiday photo.jpg';

  List<String> build({
    ImageFormat source = ImageFormat.png,
    ImageFormat target = ImageFormat.jpg,
    ImageConversionSettings settings = const ImageConversionSettings(),
  }) =>
      FfmpegImageCommandBuilder.build(
        inputPath: input,
        outputPath: output,
        source: source,
        target: target,
        settings: settings,
      );

  /// The value passed with [flag], or `null` when the flag is absent.
  String? valueOf(List<String> arguments, String flag) {
    final int index = arguments.indexOf(flag);

    return index == -1 || index + 1 >= arguments.length
        ? null
        : arguments[index + 1];
  }

  /// Every writable format, which is what the grid can actually offer.
  final List<ImageFormat> writableTargets = ImageFormat.values
      .where((format) => format.canEncode)
      .toList(growable: false);

  group('invariants across every target and preset', () {
    for (final ImageFormat target in writableTargets) {
      for (final ImageQuality preset in ImageQuality.values) {
        test('${target.label} at ${preset.name} is a well formed command', () {
          final List<String> arguments = build(
            target: target,
            settings: ImageConversionSettings(quality: preset),
          );

          expect(arguments.first, '-y');
          expect(arguments.last, output);
          expect(valueOf(arguments, '-i'), input);

          // Exactly one frame, whatever the source held.
          expect(arguments, containsAllInOrder(<String>['-frames:v', '1']));

          // Paths are never spliced into a single string, so spaces are safe.
          expect(
            arguments.where((argument) => argument.contains(' ')).length,
            2,
            reason: 'only the two paths should carry spaces',
          );
        });
      }
    }

    test('a target with no encoder is refused rather than mis-built', () {
      for (final ImageFormat target in ImageFormat.values) {
        if (target.canEncode) {
          continue;
        }

        expect(
          () => build(target: target),
          throwsArgumentError,
          reason: '${target.label} has no encoder but built a command',
        );
      }
    });
  });

  group('metadata', () {
    test('is stripped by default, GPS tag and all', () {
      expect(
        build(),
        containsAllInOrder(FfmpegImageCommandBuilder.stripMetadataArguments),
      );
    });

    test('is kept when the user asks for it', () {
      final List<String> arguments = build(
        settings: const ImageConversionSettings(keepMetadata: true),
      );

      expect(arguments, isNot(contains('-map_metadata')));
    });
  });

  // JPG to WebP: neither end involves flattening, so the plain `-vf` path is
  // the one under test here. The flattening graph is covered on its own below.
  group('sizing', () {
    List<String> resize(ImageConversionSettings settings) => build(
          source: ImageFormat.jpg,
          target: ImageFormat.webp,
          settings: settings,
        );

    test('the preset cap reaches the filter graph', () {
      final List<String> arguments = resize(
        const ImageConversionSettings(quality: ImageQuality.compact),
      );

      expect(
        valueOf(arguments, '-vf'),
        contains('${ImageQuality.compact.maxSide}'),
      );
    });

    test('High keeps the source size, so no scale filter is added', () {
      final List<String> arguments = resize(
        const ImageConversionSettings(quality: ImageQuality.high),
      );

      expect(arguments, isNot(contains('-vf')));
    });

    test('an explicit cap overrides the preset', () {
      final List<String> arguments = resize(
        const ImageConversionSettings(
          quality: ImageQuality.high,
          dimensionLimit: ImageDimensionLimit.px1920,
        ),
      );

      expect(valueOf(arguments, '-vf'), contains('1920'));
    });

    test('Original drops the preset cap', () {
      final List<String> arguments = resize(
        const ImageConversionSettings(
          quality: ImageQuality.compact,
          dimensionLimit: ImageDimensionLimit.original,
        ),
      );

      expect(arguments, isNot(contains('-vf')));
    });

    test('the commas inside min() are escaped for the filter parser', () {
      final List<String> arguments = resize(
        const ImageConversionSettings(
          dimensionLimit: ImageDimensionLimit.px800,
        ),
      );

      expect(valueOf(arguments, '-vf'), contains(r'min(iw\,800)'));
    });

    test('caps the longer side rather than the height', () {
      // Both dimensions are bounded and the aspect ratio decides which one
      // binds, which is what makes portrait and landscape shrink alike.
      final String graph = valueOf(
        resize(
          const ImageConversionSettings(
            dimensionLimit: ImageDimensionLimit.px1280,
          ),
        ),
        '-vf',
      )!;

      expect(graph, contains(r'min(iw\,1280)'));
      expect(graph, contains(r'min(ih\,1280)'));
      expect(graph, contains('force_original_aspect_ratio=decrease'));
    });
  });

  group('quality', () {
    test('JPEG runs its scale backwards: better quality is a lower number', () {
      final String best = valueOf(
        build(
          settings: const ImageConversionSettings(imageQuality: 100),
        ),
        '-q:v',
      )!;
      final String worst = valueOf(
        build(
          settings: const ImageConversionSettings(imageQuality: 0),
        ),
        '-q:v',
      )!;

      expect(int.parse(best), lessThan(int.parse(worst)));
    });

    test('WebP runs its scale forwards', () {
      final String best = valueOf(
        build(
          target: ImageFormat.webp,
          settings: const ImageConversionSettings(imageQuality: 100),
        ),
        '-q:v',
      )!;
      final String worst = valueOf(
        build(
          target: ImageFormat.webp,
          settings: const ImageConversionSettings(imageQuality: 0),
        ),
        '-q:v',
      )!;

      expect(int.parse(best), greaterThan(int.parse(worst)));
    });

    test('a lossless target is never handed a quality number', () {
      for (final ImageFormat target in <ImageFormat>[
        ImageFormat.png,
        ImageFormat.tiff,
        ImageFormat.bmp,
        ImageFormat.tga,
      ]) {
        expect(
          build(target: target),
          isNot(contains('-q:v')),
          reason: '${target.label} was given a quality it cannot use',
        );
      }
    });
  });

  group('flattening transparency', () {
    test('a transparent source going to JPEG is composited, not blackened', () {
      final List<String> arguments = build(target: ImageFormat.jpg);

      expect(valueOf(arguments, '-f'), 'lavfi');
      expect(arguments.join(' '), contains('color=c=white'));
      expect(valueOf(arguments, '-filter_complex'), contains('scale2ref'));
      expect(valueOf(arguments, '-filter_complex'), contains('overlay'));
      // The graph output is what gets encoded, not the raw input stream.
      expect(valueOf(arguments, '-map'), '[out]');
    });

    test('the chosen backdrop reaches the colour source', () {
      final List<String> arguments = build(
        settings: const ImageConversionSettings(
          background: ImageBackground.black,
        ),
      );

      expect(arguments.join(' '), contains('color=c=black'));
    });

    test('the size cap still applies inside the flattening graph', () {
      final List<String> arguments = build(
        settings: const ImageConversionSettings(
          dimensionLimit: ImageDimensionLimit.px800,
        ),
      );

      expect(valueOf(arguments, '-filter_complex'), contains('800'));
    });

    test('a source with no transparency is left on the simple path', () {
      final List<String> arguments = build(
        source: ImageFormat.jpg,
        target: ImageFormat.bmp,
      );

      expect(arguments, isNot(contains('-filter_complex')));
      expect(valueOf(arguments, '-map'), '0:v:0');
    });

    test('a target that keeps transparency is left on the simple path', () {
      final List<String> arguments = build(target: ImageFormat.webp);

      expect(arguments, isNot(contains('-filter_complex')));
      expect(valueOf(arguments, '-map'), '0:v:0');
    });
  });

  group('per format specifics', () {
    test('GIF builds its palette from the picture itself', () {
      final List<String> arguments = build(target: ImageFormat.gif);

      expect(valueOf(arguments, '-vf'), contains(FfmpegFilters.paletteGraph));
      // The filter graph is the encoder; naming one as well would fight it.
      expect(arguments, isNot(contains('-c:v')));
    });

    test('JPEG is written as 4:2:0 with even dimensions', () {
      final List<String> arguments = build();
      final String graph = valueOf(arguments, '-filter_complex')!;

      expect(valueOf(arguments, '-pix_fmt'), 'yuvj420p');
      expect(graph, contains(FfmpegFilters.evenDimensions));
    });

    test('WebP is told not to go lossless', () {
      expect(
        build(target: ImageFormat.webp),
        containsAllInOrder(<String>['-lossless', '0']),
      );
    });

    test('the image2 targets are told they write one file, not a sequence', () {
      for (final ImageFormat target in <ImageFormat>[
        ImageFormat.jpg,
        ImageFormat.png,
        ImageFormat.tiff,
        ImageFormat.bmp,
        ImageFormat.tga,
      ]) {
        expect(
          build(target: target),
          containsAllInOrder(<String>['-update', '1']),
          reason: '${target.label} would be written as a numbered sequence',
        );
      }
    });

    test('the muxers that do not know -update are never given it', () {
      for (final ImageFormat target in <ImageFormat>[
        ImageFormat.webp,
        ImageFormat.gif,
      ]) {
        expect(
          build(target: target),
          isNot(contains('-update')),
          reason: '${target.label} would reject the option outright',
        );
      }
    });
  });
}
