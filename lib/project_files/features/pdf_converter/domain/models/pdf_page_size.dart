/// Page geometry used when pictures or text are written into a PDF.
///
/// Points, not pixels: PDF measures in 1/72 inch and the writer needs the
/// numbers in the unit it will actually emit.
enum PdfPageSize {
  /// Each page takes the shape of the picture on it, so nothing is letterboxed.
  /// Meaningless for text, which has no intrinsic size — the writer falls back
  /// to [a4] there.
  fitSource(widthPoints: null, heightPoints: null),

  a4(widthPoints: 595.28, heightPoints: 841.89),
  letter(widthPoints: 612, heightPoints: 792);

  const PdfPageSize({
    required this.widthPoints,
    required this.heightPoints,
  });

  /// `null` on [fitSource], where the size comes from the picture instead.
  final double? widthPoints;
  final double? heightPoints;

  bool get followsSource => this == PdfPageSize.fitSource;
}
