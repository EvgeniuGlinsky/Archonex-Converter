import 'package:archonex_converter/project_files/features/pdf_converter/domain/models/pdf_conversion_update.dart';

/// A conversion that is already running.
///
/// A handle rather than a plain `Future` for the same reason the other
/// converters use one: the screen has to follow the work and be able to stop it
/// part way through.
abstract interface class PdfConversionJob {
  /// Emits progress and produced files as the run goes, then closes.
  ///
  /// The stream closing is what says the run is over. Unlike the image
  /// converter there is no per item failure: none of these directions can fail
  /// for one page and carry on — a PDF that lost a page is not a result anyone
  /// asked for — so any failure ends the stream with an error.
  Stream<PdfConversionUpdate> get updates;

  /// Stops the run. Whatever was already produced is discarded with it.
  Future<void> cancel();
}
