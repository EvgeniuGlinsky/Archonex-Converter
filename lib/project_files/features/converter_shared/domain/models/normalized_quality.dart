/// The one quality scale the app speaks in.
///
/// Every encoder has its own idea of what a quality number means — CRF for
/// x264, an inverted qscale for MPEG-4 and JPEG, a 0–100 dial for WebP. Presets
/// and sliders therefore all express quality on this single normalised scale,
/// and translating it into encoder units happens once, at the edge of the data
/// layer.
class NormalizedQuality {
  const NormalizedQuality._();

  /// Lowest value the scale accepts. Anything under this is grain.
  static const int min = 0;

  /// Highest value the scale accepts.
  static const int max = 100;

  static int clamp(int value) => value.clamp(min, max);
}
