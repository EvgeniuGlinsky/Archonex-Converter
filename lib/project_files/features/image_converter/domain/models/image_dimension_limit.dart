/// Cap on the longer side of the output, offered by the advanced panel.
///
/// The longer side rather than the height, because a batch of photos is
/// routinely a mix of portrait and landscape and capping the height alone would
/// shrink them by different amounts.
enum ImageDimensionLimit {
  /// Whatever the quality preset asks for. The default, so the panel can be
  /// opened and closed again without changing the outcome.
  auto(pixels: null, followsPreset: true),

  /// Keep the source size, whatever the preset says.
  original(pixels: null),

  px4096(pixels: 4096),
  px2560(pixels: 2560),
  px1920(pixels: 1920),
  px1280(pixels: 1280),
  px800(pixels: 800);

  const ImageDimensionLimit({required this.pixels, this.followsPreset = false});

  /// Longer side in pixels, or `null` when no cap of its own applies.
  final int? pixels;

  /// `true` for the entry that defers to the quality preset.
  final bool followsPreset;
}
