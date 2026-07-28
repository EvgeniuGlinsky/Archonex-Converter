import 'package:archonex_converter/project_files/features/converter_shared/domain/models/converted_file.dart';

/// One step of a running conversion.
///
/// Deliberately not indexed by source the way the image converter's updates
/// are. This converter's three directions have three different shapes — many
/// pictures collapse into one PDF, one PDF explodes into many pictures, text
/// goes one to one — so "which source is this about" has no answer that holds
/// for all of them.
///
/// Pages do hold for all of them. Every direction walks a page at a time, so
/// progress is pages done out of pages total, and produced files simply arrive
/// as they are written, however many that turns out to be.
sealed class PdfConversionUpdate {
  const PdfConversionUpdate();
}

/// [done] pages of [total] have been dealt with.
final class PdfProgressed extends PdfConversionUpdate {
  const PdfProgressed({required this.done, required this.total});

  final int done;
  final int total;
}

/// An output file finished and is sitting in the temporary directory.
///
/// Arrives once when the batch merges into a PDF, and once per page when it is
/// being read out as pictures.
final class PdfFileProduced extends PdfConversionUpdate {
  const PdfFileProduced(this.file);

  final ConvertedFile file;
}
