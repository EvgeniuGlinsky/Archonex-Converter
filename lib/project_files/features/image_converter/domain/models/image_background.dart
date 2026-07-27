/// What goes behind a transparent picture when the target cannot hold alpha.
///
/// FFmpeg's own answer is black, which is the single most surprising thing a
/// PNG to JPG conversion can do to a logo or a screenshot. White is the
/// default here for that reason.
enum ImageBackground {
  white(ffmpegColor: 'white'),
  black(ffmpegColor: 'black');

  const ImageBackground({required this.ffmpegColor});

  /// Colour name as the `color` filter source understands it.
  final String ffmpegColor;
}
