import 'package:archonex/project_files/features/converter_shared/domain/models/normalized_quality.dart';

/// The three quality presets offered on the screen.
///
/// Every codec expresses quality on its own scale — CRF for x264, a different
/// CRF range for VP9, an inverted qscale for MPEG-4, yet another one for
/// Theora. A preset therefore carries a single normalised [videoQuality]
/// between [minVideoQuality] and [maxVideoQuality]; translating it into codec
/// units is the encoder table's job, not this enum's.
enum ConversionQuality {
  high(
    videoQuality: 80,
    audioBitrateKbps: 256,
    maxHeight: null,
    animationFps: 20,
    animationWidth: 640,
  ),
  balanced(
    videoQuality: 60,
    audioBitrateKbps: 192,
    maxHeight: 1080,
    animationFps: 15,
    animationWidth: 480,
  ),
  compact(
    videoQuality: 40,
    audioBitrateKbps: 128,
    maxHeight: 720,
    animationFps: 10,
    animationWidth: 320,
  );

  const ConversionQuality({
    required this.videoQuality,
    required this.audioBitrateKbps,
    required this.maxHeight,
    required this.animationFps,
    required this.animationWidth,
  });

  /// Lowest value the normalised scale accepts. Anything under this is grain.
  static const int minVideoQuality = NormalizedQuality.min;

  /// Highest value the normalised scale accepts.
  static const int maxVideoQuality = NormalizedQuality.max;

  /// Normalised picture quality, higher is better.
  final int videoQuality;

  final int audioBitrateKbps;

  /// Cap on the output height in pixels, or `null` to keep the source size.
  /// Sources already below the cap are never upscaled.
  final int? maxHeight;

  /// Frame rate of a produced GIF or animated WebP. Above ~20 fps these grow
  /// fast without looking much better.
  final int animationFps;

  /// Width of a produced GIF or animated WebP; the height follows the ratio.
  final int animationWidth;
}
