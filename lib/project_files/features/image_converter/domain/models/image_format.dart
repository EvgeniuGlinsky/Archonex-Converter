/// Every still picture format the converter knows about.
///
/// One entry per extension, because the extension is what the picker hands
/// back and what the output file is named after. [canEncode] is what separates
/// a format FFmpeg can only read from one it can also write: a source-only
/// entry never shows up in the target list.
///
/// GIF and WebP also appear in the media converter, where they are treated as
/// animations. Here they are single frames — the two screens are different
/// tools, and the overlap is deliberate rather than accidental.
enum ImageFormat {
  jpg(
    extension: 'jpg',
    aliases: <String>['jpeg'],
    hasAlpha: false,
    hasQuality: true,
  ),
  png(extension: 'png', isLossless: true),
  webp(extension: 'webp', hasQuality: true),
  tiff(
    extension: 'tiff',
    aliases: <String>['tif'],
    isLossless: true,
  ),
  bmp(extension: 'bmp', hasAlpha: false, isLossless: true),

  /// A single frame written as a GIF: 256 colours, decided by the palette the
  /// filter graph builds, so there is no quality dial to offer.
  gif(extension: 'gif'),

  tga(extension: 'tga', isLossless: true),

  // Read only. No encoder for these ships in the bundled FFmpeg build, so they
  // can be opened and converted away from, never produced.
  ico(extension: 'ico', canEncode: false),
  heic(
    extension: 'heic',
    aliases: <String>['heif'],
    hasAlpha: false,
    canEncode: false,
  ),
  avif(extension: 'avif', canEncode: false);

  const ImageFormat({
    required this.extension,
    this.canEncode = true,
    this.hasAlpha = true,
    this.hasQuality = false,
    this.isLossless = false,
    this.aliases = const <String>[],
  });

  /// Lower case extension without the leading dot.
  final String extension;

  /// `false` for formats the bundled FFmpeg reads but has no encoder for.
  final bool canEncode;

  /// `false` where transparency cannot survive, so something has to be put
  /// behind it.
  final bool hasAlpha;

  /// `true` where the encoder takes a quality number at all. PNG, TIFF, BMP
  /// and TGA are lossless or uncompressed; GIF is decided by its palette.
  final bool hasQuality;

  final bool isLossless;

  /// Extra extensions that resolve to this same format when picking a file.
  final List<String> aliases;

  /// Upper case form shown on chips and inside copy, e.g. `JPG`.
  String get label => extension.toUpperCase();

  /// Every extension that resolves to this format, canonical one first.
  List<String> get extensions => <String>[extension, ...aliases];

  /// Whether the quality slider means anything once this is the target.
  bool get supportsQuality => hasQuality;

  /// Whether a colour has to be put behind the picture before writing it.
  ///
  /// Only worth asking about when the source could carry transparency in the
  /// first place — a JPG turned into a BMP has nothing to flatten.
  bool needsBackgroundFrom(ImageFormat source) => !hasAlpha && source.hasAlpha;

  /// Extensions the file picker is opened with, aliases included.
  static List<String> get pickableExtensions => <String>[
        for (final ImageFormat format in ImageFormat.values)
          ...format.extensions,
      ];

  /// The format behind [extension], or `null` when it is not supported.
  static ImageFormat? fromExtension(String extension) {
    final String normalized = extension.toLowerCase();

    for (final ImageFormat format in ImageFormat.values) {
      if (format.extensions.contains(normalized)) {
        return format;
      }
    }

    return null;
  }

  /// Every format that can be produced, this one aside.
  ///
  /// A still picture can become any other still picture, so unlike the media
  /// converter there is no matrix to derive: the only exclusions are formats
  /// with no encoder and the source format itself, which would be a re-encode
  /// the screen has no way to explain.
  List<ImageFormat> get targets => ImageFormat.values
      .where((candidate) => candidate.canEncode && candidate != this)
      .toList(growable: false);

  /// Formats reachable from every one of [sources].
  ///
  /// A mixed batch keeps the union rather than the intersection, minus only
  /// the formats that would leave part of the batch converting to itself.
  static List<ImageFormat> targetsFor(Iterable<ImageFormat> sources) {
    final Set<ImageFormat> present = sources.toSet();

    return ImageFormat.values
        .where(
          (candidate) =>
              candidate.canEncode &&
              !(present.length == 1 && present.contains(candidate)),
        )
        .toList(growable: false);
  }
}
