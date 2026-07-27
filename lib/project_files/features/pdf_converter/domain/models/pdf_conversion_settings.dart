import 'package:equatable/equatable.dart';

import 'package:archonex_converter/project_files/features/converter_shared/domain/models/normalized_quality.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/domain/models/pdf_page_size.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/domain/models/pdf_target.dart';

/// One set of settings for the whole run.
///
/// The two directions use disjoint halves of this: [pageSize] and [marginPoints]
/// only mean something while writing a PDF, [rasterDpi] and [quality] only while
/// reading one out as pictures. Keeping them in one object rather than two keeps
/// the bloc from having to swap models when the target changes; [prunedFor]
/// drops whatever the current target cannot use.
class PdfConversionSettings extends Equatable {
  const PdfConversionSettings({
    this.pageSize = PdfPageSize.fitSource,
    this.marginPoints = defaultMarginPoints,
    this.rasterDpi = defaultRasterDpi,
    this.quality = defaultQuality,
  });

  /// Wide enough to look intentional, narrow enough not to shrink a photo.
  static const double defaultMarginPoints = 24;

  /// 150 dpi renders a text page sharply on screen without producing the
  /// 20 MB per page that 300 dpi would.
  static const int defaultRasterDpi = 150;

  static const int defaultQuality = 85;

  /// Rungs offered in the advanced panel. Screen, print, and the two either
  /// side, rather than a slider over a scale nobody reads in dots per inch.
  static const List<int> rasterDpiOptions = <int>[72, 150, 300, 600];

  final PdfPageSize pageSize;
  final double marginPoints;
  final int rasterDpi;
  final int quality;

  /// Page geometry never applies when the batch is being read *out* of a PDF.
  bool appliesPageSizeFor(PdfTarget target) => target.mergesBatch;

  /// Resolution only applies in the other direction, and quality only when the
  /// picture format has a dial at all.
  bool appliesRasterDpiFor(PdfTarget target) => !target.mergesBatch;

  bool appliesQualityFor(PdfTarget target) =>
      !target.mergesBatch && target.supportsQuality;

  /// The same settings with everything [target] cannot use put back to its
  /// default, so a value tuned for one direction cannot survive into the other
  /// and quietly change a result nobody asked it to.
  PdfConversionSettings prunedFor(PdfTarget target) => PdfConversionSettings(
        pageSize: appliesPageSizeFor(target) ? pageSize : PdfPageSize.fitSource,
        marginPoints:
            appliesPageSizeFor(target) ? marginPoints : defaultMarginPoints,
        rasterDpi: appliesRasterDpiFor(target) ? rasterDpi : defaultRasterDpi,
        quality: appliesQualityFor(target) ? quality : defaultQuality,
      );

  PdfConversionSettings copyWith({
    PdfPageSize? pageSize,
    double? marginPoints,
    int? rasterDpi,
    int? quality,
  }) =>
      PdfConversionSettings(
        pageSize: pageSize ?? this.pageSize,
        marginPoints: marginPoints ?? this.marginPoints,
        rasterDpi: rasterDpi ?? this.rasterDpi,
        quality: quality == null
            ? this.quality
            : NormalizedQuality.clamp(quality),
      );

  @override
  List<Object?> get props =>
      <Object?>[pageSize, marginPoints, rasterDpi, quality];
}
