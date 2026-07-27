/// What kind of thing a picked file is, from the PDF converter's point of view.
///
/// The converter has three directions rather than a format matrix, and the kind
/// of the batch is what picks one: pictures and text go *into* a PDF, a PDF
/// comes *out* as pictures.
enum PdfSourceKind { image, pdf, text }

/// Every file the PDF converter will open.
///
/// One entry per extension, because the extension is what the picker hands back
/// and what decides the direction. Unlike the image converter there is no
/// `canEncode` flag: what can be produced is a [PdfTarget], a much shorter list
/// than what can be read.
enum PdfFormat {
  jpg(extension: 'jpg', aliases: <String>['jpeg'], kind: PdfSourceKind.image),
  png(extension: 'png', kind: PdfSourceKind.image),
  webp(extension: 'webp', kind: PdfSourceKind.image),
  bmp(extension: 'bmp', kind: PdfSourceKind.image),
  tiff(extension: 'tiff', aliases: <String>['tif'], kind: PdfSourceKind.image),
  gif(extension: 'gif', kind: PdfSourceKind.image),

  pdf(extension: 'pdf', kind: PdfSourceKind.pdf),

  txt(extension: 'txt', kind: PdfSourceKind.text),
  md(extension: 'md', aliases: <String>['markdown'], kind: PdfSourceKind.text);

  const PdfFormat({
    required this.extension,
    required this.kind,
    this.aliases = const <String>[],
  });

  /// Lower case extension without the leading dot.
  final String extension;

  final PdfSourceKind kind;

  /// Extra extensions that resolve to this same format when picking a file.
  final List<String> aliases;

  /// Upper case form shown on chips and inside copy, e.g. `PNG`.
  String get label => extension.toUpperCase();

  /// Every extension that resolves to this format, canonical one first.
  List<String> get extensions => <String>[extension, ...aliases];

  /// Extensions the file picker is opened with, aliases included.
  static List<String> get pickableExtensions => <String>[
        for (final PdfFormat format in PdfFormat.values) ...format.extensions,
      ];

  /// The format behind [extension], or `null` when it is not supported.
  static PdfFormat? fromExtension(String extension) {
    final String normalized = extension.toLowerCase();

    for (final PdfFormat format in PdfFormat.values) {
      if (format.extensions.contains(normalized)) {
        return format;
      }
    }

    return null;
  }

  /// The one kind every file in [sources] shares, or `null` when they disagree.
  ///
  /// A mixed batch has no direction — pictures and a PDF in the same run would
  /// have to go opposite ways at once — so it is refused rather than guessed at.
  static PdfSourceKind? sharedKind(Iterable<PdfFormat> sources) {
    final Set<PdfSourceKind> kinds =
        sources.map((format) => format.kind).toSet();

    return kinds.length == 1 ? kinds.first : null;
  }
}
