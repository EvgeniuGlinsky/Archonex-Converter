import 'package:flutter_test/flutter_test.dart';

import 'package:archonex_converter/project_files/features/media_converter/data/ffmpeg/ffmpeg_codecs.dart';
import 'package:archonex_converter/project_files/features/media_converter/data/ffmpeg/ffmpeg_command_builder.dart';
import 'package:archonex_converter/project_files/features/media_converter/data/ffmpeg/ffmpeg_target_spec.dart';
import 'package:archonex_converter/project_files/features/media_converter/domain/models/audio_bitrate_option.dart';
import 'package:archonex_converter/project_files/features/media_converter/domain/models/conversion_quality.dart';
import 'package:archonex_converter/project_files/features/media_converter/domain/models/conversion_settings.dart';
import 'package:archonex_converter/project_files/features/media_converter/domain/models/frame_rate_option.dart';
import 'package:archonex_converter/project_files/features/media_converter/domain/models/media_format.dart';
import 'package:archonex_converter/project_files/features/media_converter/domain/models/video_resolution.dart';

void main() {
  // A path with a space is the case an argument list exists to survive.
  const String input = r'C:\Users\me\My Videos\clip.mp4';
  const String output = r'C:\Temp\archonex_convert_1\clip.out';

  List<String> argsFor(
    MediaFormat target, {
    ConversionSettings settings = const ConversionSettings(),
  }) =>
      FfmpegCommandBuilder.build(
        inputPath: input,
        outputPath: output,
        target: target,
        settings: settings,
      );

  /// The single argument following [flag].
  String valueAfter(List<String> args, String flag) =>
      args[args.indexOf(flag) + 1];

  final List<MediaFormat> encodable = MediaFormat.values
      .where((format) => format.canEncode)
      .toList(growable: false);

  group('invariants across every target and preset', () {
    for (final MediaFormat target in encodable) {
      for (final ConversionQuality quality in ConversionQuality.values) {
        test('${target.label} at ${quality.name} is well formed', () {
          final List<String> args = argsFor(
            target,
            settings: ConversionSettings(quality: quality),
          );

          // Never ask before overwriting, so a rerun cannot hang.
          expect(args, contains('-y'));
          expect(valueAfter(args, '-i'), input);
          expect(args.last, output);
          expect(args.any((argument) => argument.isEmpty), isFalse);
          expect(args.any((argument) => argument.contains('null')), isFalse);

          final bool isAudioOnly = FfmpegTargetSpec.of(target)!.isAudioOnly;
          expect(args.contains('-vn'), isAudioOnly);
          if (isAudioOnly) {
            expect(args, isNot(contains('-c:v')));
          }
        });
      }
    }

    test('only the animations loop', () {
      for (final MediaFormat target in encodable) {
        expect(
          argsFor(target).contains('-loop'),
          target.isAnimation,
          reason: '${target.label} disagrees about looping',
        );
      }
    });
  });

  group('MP4', () {
    late List<String> args;

    setUp(() => args = argsFor(MediaFormat.mp4));

    test('encodes h264 and aac', () {
      expect(valueAfter(args, '-c:v'), 'libx264');
      expect(valueAfter(args, '-c:a'), 'aac');
    });

    test('the balanced preset keeps the CRF the old converter used', () {
      expect(valueAfter(args, '-crf'), '23');
    });

    test('forces yuv420p with even dimensions', () {
      // libx264 rejects odd width or height in this pixel format, and sources
      // — GIFs above all — routinely have them.
      expect(valueAfter(args, '-pix_fmt'), 'yuv420p');
      expect(
        valueAfter(args, '-vf'),
        endsWith(FfmpegCommandBuilder.evenDimensionsFilter),
      );
    });

    test('places the moov atom up front for streaming', () {
      expect(valueAfter(args, '-movflags'), '+faststart');
    });

    test('takes one video and one optional audio stream, nothing else', () {
      expect(args, containsAllInOrder(<String>['-map', '0:v:0']));
      expect(args, contains('0:a:0?'));
      expect(args, contains('-sn'));
      expect(args, contains('-dn'));
    });
  });

  test('M4V names the MP4 muxer, which the extension alone does not', () {
    // `.m4v` otherwise resolves to the raw MPEG-4 video muxer and the audio
    // track disappears without an error.
    expect(valueAfter(argsFor(MediaFormat.m4v), '-f'), 'mp4');
    expect(argsFor(MediaFormat.mp4), isNot(contains('-f')));
  });

  test('WEBM drives VP9 in constant quality mode', () {
    final List<String> args = argsFor(MediaFormat.webm);

    expect(valueAfter(args, '-c:v'), 'libvpx-vp9');
    // Without `-b:v 0` libvpx reads -crf as a ceiling and the file balloons.
    expect(valueAfter(args, '-b:v'), '0');
    expect(valueAfter(args, '-c:a'), 'libopus');
  });

  test('AVI tags the stream so legacy players recognise it', () {
    final List<String> args = argsFor(MediaFormat.avi);

    expect(valueAfter(args, '-c:v'), 'mpeg4');
    expect(valueAfter(args, '-q:v'), '6');
    expect(valueAfter(args, '-vtag'), 'xvid');
    expect(valueAfter(args, '-c:a'), 'libmp3lame');
  });

  group('GIF', () {
    test('generates and applies a palette from the clip itself', () {
      final String filter = valueAfter(argsFor(MediaFormat.gif), '-vf');

      expect(filter, contains('palettegen'));
      expect(filter, contains('paletteuse'));
    });

    test('the balanced filter is the one the old converter produced', () {
      expect(
        valueAfter(argsFor(MediaFormat.gif), '-vf'),
        'fps=15,scale=480:-1:flags=lanczos,'
        '${FfmpegCommandBuilder.paletteGraph}',
      );
    });

    test('the compact preset drops the rate and the width', () {
      final String filter = valueAfter(
        argsFor(
          MediaFormat.gif,
          settings: const ConversionSettings(quality: ConversionQuality.compact),
        ),
        '-vf',
      );

      expect(filter, startsWith('fps=10,scale=320:-1'));
    });

    test('carries no audio and no explicit codec', () {
      final List<String> args = argsFor(MediaFormat.gif);

      expect(args, contains('-an'));
      expect(args, isNot(contains('-c:v')));
      expect(valueAfter(args, '-loop'), '0');
    });
  });

  test('WEBP encodes with libwebp and never duplicates frames', () {
    final List<String> args = argsFor(MediaFormat.webp);

    expect(valueAfter(args, '-c:v'), 'libwebp');
    expect(valueAfter(args, '-fps_mode'), 'passthrough');
    expect(args, contains('-an'));
  });

  group('audio targets', () {
    test('drop the picture and name the audio stream explicitly', () {
      final List<String> args = argsFor(MediaFormat.mp3);

      expect(args, contains('-vn'));
      expect(args, contains('0:a:0'));
      expect(args, isNot(contains('-vf')));
    });

    test('each reaches for its own encoder', () {
      expect(valueAfter(argsFor(MediaFormat.mp3), '-c:a'), 'libmp3lame');
      expect(valueAfter(argsFor(MediaFormat.m4a), '-c:a'), 'aac');
      expect(valueAfter(argsFor(MediaFormat.wav), '-c:a'), 'pcm_s16le');
      expect(valueAfter(argsFor(MediaFormat.flac), '-c:a'), 'flac');
      expect(valueAfter(argsFor(MediaFormat.ogg), '-c:a'), 'libvorbis');
      expect(valueAfter(argsFor(MediaFormat.opus), '-c:a'), 'libopus');
    });

    test('a bitrate is passed only where it means something', () {
      expect(argsFor(MediaFormat.mp3), contains('-b:a'));
      expect(argsFor(MediaFormat.wav), isNot(contains('-b:a')));
      expect(argsFor(MediaFormat.flac), isNot(contains('-b:a')));
    });

    test('WAV comes out the same whatever the preset says', () {
      expect(
        argsFor(
          MediaFormat.wav,
          settings: const ConversionSettings(quality: ConversionQuality.high),
        ),
        argsFor(
          MediaFormat.wav,
          settings: const ConversionSettings(quality: ConversionQuality.compact),
        ),
      );
    });
  });

  group('advanced overrides', () {
    test('a resolution caps the height without upscaling a smaller source', () {
      final String filter = valueAfter(
        argsFor(
          MediaFormat.mp4,
          settings: const ConversionSettings(resolution: VideoResolution.hd),
        ),
        '-vf',
      );

      expect(filter, contains(r'scale=-2:min(ih\,720)'));
    });

    test('the original resolution drops the scale filter entirely', () {
      final String filter = valueAfter(
        argsFor(
          MediaFormat.mp4,
          settings: const ConversionSettings(
            resolution: VideoResolution.source,
          ),
        ),
        '-vf',
      );

      expect(filter, FfmpegCommandBuilder.evenDimensionsFilter);
    });

    test('a frame rate leads the filter chain', () {
      final String filter = valueAfter(
        argsFor(
          MediaFormat.mp4,
          settings: const ConversionSettings(frameRate: FrameRateOption.fps24),
        ),
        '-vf',
      );

      expect(filter, startsWith('fps=24,'));
    });

    test('the quality slider maps onto each encoder own scale', () {
      String crfAt(int value, MediaFormat target) => valueAfter(
            argsFor(
              target,
              settings: ConversionSettings(videoQuality: value),
            ),
            target == MediaFormat.mp4 ? '-crf' : '-q:v',
          );

      expect(
        crfAt(ConversionQuality.maxVideoQuality, MediaFormat.mp4),
        '${FfmpegVideoCodec.x264.bestValue}',
      );
      expect(
        crfAt(ConversionQuality.minVideoQuality, MediaFormat.mp4),
        '${FfmpegVideoCodec.x264.worstValue}',
      );
      // Theora runs its scale the other way round.
      expect(
        crfAt(ConversionQuality.maxVideoQuality, MediaFormat.ogv),
        '${FfmpegVideoCodec.theora.bestValue}',
      );
    });

    test('an explicit bitrate wins over the preset', () {
      expect(
        valueAfter(
          argsFor(
            MediaFormat.mp3,
            settings: const ConversionSettings(
              audioBitrate: AudioBitrateOption.kbps320,
            ),
          ),
          '-b:a',
        ),
        '320k',
      );
    });

    test('turning audio off silences a video target', () {
      final List<String> args = argsFor(
        MediaFormat.mp4,
        settings: const ConversionSettings(keepAudio: false),
      );

      expect(args, contains('-an'));
      expect(args, isNot(contains('-c:a')));
      expect(args, isNot(contains('0:a:0?')));
    });

    test('turning audio off cannot silence an audio target', () {
      final List<String> args = argsFor(
        MediaFormat.mp3,
        settings: const ConversionSettings(keepAudio: false),
      );

      expect(valueAfter(args, '-c:a'), 'libmp3lame');
      expect(args, isNot(contains('-an')));
    });
  });

  test('a format with no encoder is rejected rather than half built', () {
    expect(
      () => argsFor(MediaFormat.wmv),
      throwsA(isA<ArgumentError>()),
    );
  });
}
