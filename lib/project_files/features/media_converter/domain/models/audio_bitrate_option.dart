/// Output audio bitrate offered by the advanced panel.
///
/// [preset] follows whichever quality preset is selected, so the panel does not
/// have to be reset to get the default behaviour back.
enum AudioBitrateOption {
  preset(kbps: null),
  kbps320(kbps: 320),
  kbps256(kbps: 256),
  kbps192(kbps: 192),
  kbps128(kbps: 128),
  kbps96(kbps: 96),
  kbps64(kbps: 64);

  const AudioBitrateOption({required this.kbps});

  /// Bitrate in kbit/s, or `null` to follow the quality preset.
  final int? kbps;
}
