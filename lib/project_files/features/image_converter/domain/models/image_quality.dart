import 'package:archonex_converter/project_files/features/converter_shared/domain/models/normalized_quality.dart';

/// The three quality presets offered on the image screen.
///
/// A preset says two things at once, because for photos they are the same
/// decision: how hard to compress, and how far to shrink. Cutting a 48
/// megapixel phone photo down to 2560 px saves far more than any quality
/// setting can, so a preset that only touched compression would be a lie.
enum ImageQuality {
  high(quality: 92, maxSide: null),
  balanced(quality: 80, maxSide: 2560),
  compact(quality: 62, maxSide: 1440);

  const ImageQuality({required this.quality, required this.maxSide});

  /// Lowest value the normalised scale accepts.
  static const int minQuality = NormalizedQuality.min;

  /// Highest value the normalised scale accepts.
  static const int maxQuality = NormalizedQuality.max;

  /// Normalised picture quality, higher is better.
  final int quality;

  /// Cap on the longer side in pixels, or `null` to keep the source size.
  /// Pictures already below the cap are never upscaled.
  final int? maxSide;
}
