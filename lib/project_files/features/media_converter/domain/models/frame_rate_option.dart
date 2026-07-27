/// Output frame rate offered by the advanced panel.
enum FrameRateOption {
  /// Whatever the target and the quality preset ask for: the source rate for a
  /// video, the preset rate for a GIF or an animated WebP.
  auto(fps: null, followsPreset: true, label: 'Auto'),

  /// Keep the source rate even for an animation, where that gets expensive.
  source(fps: null, followsPreset: false, label: 'Original'),

  fps60(fps: 60),
  fps30(fps: 30),
  fps24(fps: 24),
  fps15(fps: 15),
  fps12(fps: 12);

  const FrameRateOption({
    required this.fps,
    this.followsPreset = false,
    String? label,
  }) : _label = label;

  /// Frames per second, or `null` when the source rate is kept.
  final int? fps;

  /// `true` for the entry that defers to the target and the quality preset.
  final bool followsPreset;

  final String? _label;

  /// `Auto`, `Original`, `30 fps` …
  String get label => _label ?? '$fps $_unit';

  static const String _unit = 'fps';
}
