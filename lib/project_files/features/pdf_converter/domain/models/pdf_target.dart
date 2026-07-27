import 'package:archonex_converter/project_files/features/pdf_converter/domain/models/pdf_format.dart';

/// Everything the PDF converter can produce.
///
/// Far shorter than the list it can read: the point of the screen is the two
/// directions across the PDF boundary, not a format matrix.
enum PdfTarget {
  pdf(extension: 'pdf'),
  png(extension: 'png'),
  jpg(extension: 'jpg');

  const PdfTarget({required this.extension});

  /// Lower case extension without the leading dot.
  final String extension;

  /// Upper case form shown on chips and inside copy, e.g. `PDF`.
  String get label => extension.toUpperCase();

  /// `true` where the encoder takes a quality number at all. PNG is lossless,
  /// and a PDF carrying already encoded pictures re-encodes nothing.
  bool get supportsQuality => this == PdfTarget.jpg;

  /// Whether the whole batch collapses into one output file.
  ///
  /// This is the rule that makes three directions one screen: aiming at a PDF
  /// merges, aiming at a picture explodes. Everything downstream — progress,
  /// the results card, the save button — reads off this single question.
  bool get mergesBatch => this == PdfTarget.pdf;

  /// What can be produced from a batch that is entirely [kind].
  ///
  /// `null` means the batch has no direction at all, which is what a mixed pick
  /// produces — see `PdfFormat.sharedKind`.
  static List<PdfTarget> targetsFor(PdfSourceKind? kind) => switch (kind) {
        PdfSourceKind.image ||
        PdfSourceKind.text =>
          const <PdfTarget>[PdfTarget.pdf],
        PdfSourceKind.pdf => const <PdfTarget>[PdfTarget.png, PdfTarget.jpg],
        null => const <PdfTarget>[],
      };
}
