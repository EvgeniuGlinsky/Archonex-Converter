import 'package:archonex_converter/project_files/features/converter_shared/domain/models/normalized_quality.dart';

/// Turns a normalised quality into the number one encoder actually wants.
///
/// Linear between [bestValue] and [worstValue], which also covers the inverted
/// scales — JPEG, Theora and WebP all run backwards — because nothing here
/// assumes one end is larger than the other.
int ffmpegQualityArgument({
  required int normalized,
  required int bestValue,
  required int worstValue,
}) {
  const int span = NormalizedQuality.max - NormalizedQuality.min;
  final int distanceFromBest =
      NormalizedQuality.max - NormalizedQuality.clamp(normalized);

  return (bestValue + (worstValue - bestValue) * distanceFromBest / span)
      .round();
}

/// One encoder's quality dial: which flag it listens to, and what the two ends
/// of its own scale are.
///
/// Modelled as an object rather than as three fields on the codec so a codec
/// that has no dial at all can simply not have one, instead of carrying
/// numbers that mean nothing.
class FfmpegQualityScale {
  const FfmpegQualityScale({
    required this.flag,
    required this.bestValue,
    required this.worstValue,
  });

  /// Flag the number is passed with, `-crf` or `-q:v`.
  final String flag;

  /// Codec value standing for the best picture this encoder should produce.
  final int bestValue;

  /// Codec value standing for the worst picture still worth producing.
  final int worstValue;

  /// The flag and its value, ready to splice into an argument list.
  List<String> argumentsFor(int normalized) => <String>[
        flag,
        '${ffmpegQualityArgument(
          normalized: normalized,
          bestValue: bestValue,
          worstValue: worstValue,
        )}',
      ];
}
