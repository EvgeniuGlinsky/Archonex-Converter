import 'package:flutter_test/flutter_test.dart';

import 'package:archonex/project_files/features/media_converter/data/ffmpeg/ffmpeg_target_spec.dart';
import 'package:archonex/project_files/features/media_converter/domain/models/media_format.dart';

void main() {
  group('lookup', () {
    test('resolves an extension whatever its case', () {
      expect(MediaFormat.fromExtension('MP4'), MediaFormat.mp4);
      expect(MediaFormat.fromExtension('mp4'), MediaFormat.mp4);
    });

    test('resolves the alias extensions onto their canonical format', () {
      expect(MediaFormat.fromExtension('mpeg'), MediaFormat.mpg);
      expect(MediaFormat.fromExtension('oga'), MediaFormat.ogg);
      expect(MediaFormat.fromExtension('aif'), MediaFormat.aiff);
    });

    test('returns null for anything it does not know', () {
      expect(MediaFormat.fromExtension('psd'), isNull);
      expect(MediaFormat.fromExtension(''), isNull);
    });

    test('offers every extension to the picker, without duplicates', () {
      final List<String> extensions = MediaFormat.pickableExtensions;

      expect(extensions, contains('mp4'));
      expect(extensions, contains('mpeg'));
      expect(extensions.every((value) => !value.startsWith('.')), isTrue);
      expect(extensions.toSet(), hasLength(extensions.length));
    });
  });

  group('target matrix', () {
    test('a video reaches other videos, animations and audio', () {
      final List<MediaFormat> targets = MediaFormat.mp4.targets;

      expect(targets, contains(MediaFormat.mkv));
      expect(targets, contains(MediaFormat.webm));
      expect(targets, contains(MediaFormat.gif));
      expect(targets, contains(MediaFormat.mp3));
    });

    test('an animation reaches video but never audio', () {
      final List<MediaFormat> targets = MediaFormat.gif.targets;

      expect(targets, contains(MediaFormat.mp4));
      expect(targets, contains(MediaFormat.webp));
      expect(targets.any((format) => format.isAudio), isFalse);
    });

    test('audio reaches audio only — no pictures can be invented', () {
      final List<MediaFormat> targets = MediaFormat.mp3.targets;

      expect(targets, isNotEmpty);
      expect(targets.every((format) => format.isAudio), isTrue);
    });

    test('nothing converts to itself', () {
      for (final MediaFormat format in MediaFormat.values) {
        expect(format.targets, isNot(contains(format)));
      }
    });

    test('a decode only format is a source but never a target', () {
      expect(MediaFormat.wmv.targets, isNotEmpty);

      for (final MediaFormat format in MediaFormat.values) {
        expect(format.targets, isNot(contains(MediaFormat.wmv)));
        expect(format.targets, isNot(contains(MediaFormat.wma)));
      }
    });

    test('every format can become something', () {
      for (final MediaFormat format in MediaFormat.values) {
        expect(format.targets, isNotEmpty, reason: '$format is a dead end');
      }
    });
  });

  test('every reachable target has an encoder spec behind it', () {
    for (final MediaFormat source in MediaFormat.values) {
      for (final MediaFormat target in source.targets) {
        expect(
          FfmpegTargetSpec.of(target),
          isNotNull,
          reason: '$target is offered but has no spec',
        );
      }
    }
  });

  test('a spec exists exactly for the encodable formats', () {
    for (final MediaFormat format in MediaFormat.values) {
      expect(
        FfmpegTargetSpec.of(format) != null,
        format.canEncode,
        reason: '$format disagrees with its spec',
      );
    }
  });
}
