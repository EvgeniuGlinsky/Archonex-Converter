/// Filter fragments more than one converter needs.
///
/// Kept as named constants rather than inline strings because an FFmpeg filter
/// graph is unreadable enough without also being anonymous.
class FfmpegFilters {
  const FfmpegFilters._();

  /// Lanczos gives visibly better downscales than the default bilinear, at a
  /// cost that does not matter for a single frame or for a clip being
  /// re-encoded anyway.
  static const String scaleFlags = 'flags=lanczos';

  /// Single pass palettegen + paletteuse.
  ///
  /// A plain `-i in.mp4 out.gif` quantises to a generic 256 colour palette and
  /// bands badly. Generating a palette from the source itself and applying it
  /// in the same graph costs nothing extra and looks far better.
  static const String paletteGraph = 'split[a][b];'
      '[a]palettegen=stats_mode=diff[p];'
      '[b][p]paletteuse=dither=bayer:bayer_scale=5:diff_mode=rectangle';

  /// libx264 and friends reject odd dimensions in `yuv420p`, and sources —
  /// GIFs above all — routinely have them.
  static const String evenDimensions = 'scale=trunc(iw/2)*2:trunc(ih/2)*2';
}
