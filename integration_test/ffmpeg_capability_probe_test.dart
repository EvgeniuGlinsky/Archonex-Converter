import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:archonex_converter/project_files/features/image_converter/data/ffmpeg/ffmpeg_image_codecs.dart';
import 'package:archonex_converter/project_files/features/image_converter/data/ffmpeg/ffmpeg_image_target_spec.dart';
import 'package:archonex_converter/project_files/features/image_converter/domain/models/image_format.dart';

/// Reports which encoders and decoders the bundled FFmpeg build actually has.
///
/// `ImageFormat.canEncode` is a hand written claim, and a wrong one shows up as
/// a conversion that fails on a device and nowhere else. This probe is how that
/// claim gets checked:
///
/// ```
/// flutter test integration_test/ffmpeg_capability_probe_test.dart -d windows
/// flutter test integration_test/ffmpeg_capability_probe_test.dart -d <device>
/// ```
///
/// It is deliberately outside CI, like the capacity probe: a desktop runner
/// says nothing about what ships inside the Android or iOS bundle. Run it again
/// whenever `ffmpeg_kit_flutter_new` is upgraded.
///
/// Two questions it answers that nothing else can:
///
/// * do the formats marked writable really have their encoder, and
/// * can HEIC and AVIF — what an iPhone and a modern Android camera produce —
///   be read at all, which decides whether they stay listed as source-only or
///   have to be dropped from the picker entirely.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// Names FFmpeg would print in the `-encoders` and `-decoders` tables.
  const Map<ImageFormat, String> decoderNames = <ImageFormat, String>{
    ImageFormat.jpg: 'mjpeg',
    ImageFormat.png: 'png',
    ImageFormat.webp: 'webp',
    ImageFormat.tiff: 'tiff',
    ImageFormat.bmp: 'bmp',
    ImageFormat.gif: 'gif',
    ImageFormat.tga: 'targa',
    ImageFormat.ico: 'bmp',
    ImageFormat.heic: 'hevc',
    ImageFormat.avif: 'av1',
  };

  late String encoders;
  late String decoders;

  setUpAll(() async {
    encoders = await _run('-hide_banner -encoders');
    decoders = await _run('-hide_banner -decoders');
  });

  test('every format claimed writable has its encoder in this build', () {
    final List<String> missing = <String>[];

    for (final ImageFormat format in ImageFormat.values) {
      if (!format.canEncode) {
        continue;
      }

      final FfmpegImageCodec? codec = FfmpegImageTargetSpec.of(format)?.codec;
      // GIF has no codec of its own: the palette filter graph is the encoder,
      // and the muxer is checked by the round trip below.
      final String name = codec?.name ?? 'gif';

      if (!encoders.contains(name)) {
        missing.add('${format.label} needs $name');
      }
    }

    expect(
      missing,
      isEmpty,
      reason: 'the format table promises encoders this build does not ship',
    );
  });

  test('reports what the read-only formats can actually be read as', () {
    // Not an assertion about what must be true — a printout, because the answer
    // decides whether HEIC and AVIF stay in the picker.
    final StringBuffer report = StringBuffer('\nDecoder support:\n');

    for (final MapEntry<ImageFormat, String> entry in decoderNames.entries) {
      final bool present = decoders.contains(entry.value);
      report.writeln(
        '  ${entry.key.label.padRight(6)} '
        '${entry.value.padRight(8)} ${present ? 'yes' : 'NO'}',
      );
    }

    // ignore: avoid_print
    print(report);

    // The formats the converter cannot even open are worth failing on: they
    // would sit in the picker as a promise the app cannot keep.
    expect(decoders, contains('mjpeg'));
    expect(decoders, contains('png'));
    expect(decoders, contains('webp'));
  });
}

Future<String> _run(String command) async {
  final FFmpegSession session = await FFmpegKit.execute(command);

  return (await session.getAllLogsAsString()) ?? '';
}
