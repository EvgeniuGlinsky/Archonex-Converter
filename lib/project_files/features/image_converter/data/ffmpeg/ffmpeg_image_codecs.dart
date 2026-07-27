import 'package:archonex/project_files/features/converter_shared/data/ffmpeg/ffmpeg_quality_scale.dart';

/// The still image encoders the bundled FFmpeg build can write with.
///
/// Only two of them have a quality dial at all; the rest are lossless or
/// uncompressed, where a quality number would be quietly ignored. That is why
/// [quality] is nullable rather than a pair of meaningless numbers.
enum FfmpegImageCodec {
  /// JPEG. Its scale runs backwards — 2 is best, 31 is worst — which the
  /// shared quality mapping already handles.
  mjpeg(
    name: 'mjpeg',
    quality: FfmpegQualityScale(flag: '-q:v', bestValue: 2, worstValue: 31),
    pixelFormat: yuv420p,
  ),

  /// WebP. Also inverted, and it needs telling not to go lossless: lossless
  /// output of a photograph is routinely larger than the JPEG it came from.
  webp(
    name: 'libwebp',
    quality: FfmpegQualityScale(flag: '-q:v', bestValue: 95, worstValue: 30),
    extraArguments: <String>['-lossless', '0', '-preset', 'picture'],
  ),

  /// PNG is lossless, so `-compression_level` trades encode time for size
  /// rather than quality for size. 7 is the point past which the extra seconds
  /// stop buying meaningful bytes.
  png(
    name: 'png',
    extraArguments: <String>['-compression_level', '7', '-pred', 'mixed'],
  ),

  /// Uncompressed TIFF is enormous and nothing gains from it; deflate is
  /// lossless and universally read.
  tiff(
    name: 'tiff',
    extraArguments: <String>['-compression_algo', 'deflate'],
  ),

  bmp(name: 'bmp'),
  targa(name: 'targa');

  const FfmpegImageCodec({
    required this.name,
    this.quality,
    this.pixelFormat,
    this.extraArguments = const <String>[],
  });

  /// 4:2:0 chroma, which is what makes a JPEG readable by everything. It also
  /// rejects odd dimensions, which is why the command builder pairs it with an
  /// even-dimensions filter.
  static const String yuv420p = 'yuvj420p';

  /// Encoder name as FFmpeg knows it.
  final String name;

  /// The quality dial, or `null` where the encoder has none.
  final FfmpegQualityScale? quality;

  /// Pixel format to force, or `null` to leave FFmpeg's choice alone.
  final String? pixelFormat;

  final List<String> extraArguments;

  /// `true` where odd dimensions are rejected outright.
  bool get needsEvenDimensions => pixelFormat == yuv420p;

  /// The quality flag and its value for this encoder, or nothing at all when
  /// the encoder has no dial.
  List<String> qualityArguments(int normalized) =>
      quality?.argumentsFor(normalized) ?? const <String>[];
}
