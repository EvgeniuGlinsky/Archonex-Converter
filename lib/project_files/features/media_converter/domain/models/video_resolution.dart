/// Output height offered by the advanced panel.
///
/// Only a cap is expressed: a source shorter than the chosen height is left
/// alone, because upscaling adds bytes and no detail.
enum VideoResolution {
  /// Whatever the quality preset asks for. The default, so the panel can be
  /// opened and closed again without changing the outcome.
  auto(height: null, followsPreset: true),

  /// Keep the source size, whatever the preset says.
  source(height: null, followsPreset: false),

  uhd(height: 2160),
  qhd(height: 1440),
  fullHd(height: 1080),
  hd(height: 720),
  sd(height: 480),
  low(height: 360);

  const VideoResolution({required this.height, this.followsPreset = false});

  /// Height in pixels, or `null` when no cap applies.
  final int? height;

  /// `true` for the entry that defers to the quality preset.
  final bool followsPreset;
}
