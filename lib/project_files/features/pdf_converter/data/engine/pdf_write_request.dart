import 'dart:isolate';

import 'package:archonex_converter/project_files/features/pdf_converter/domain/models/pdf_conversion_settings.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/domain/models/pdf_format.dart';

/// Everything the background isolate needs to write one PDF.
///
/// Paths rather than bytes: `dart:io` works inside an isolate, so the sources
/// are read there and never crossed over the port. Only the font has to travel,
/// because it comes from the asset bundle, which is bound to the main isolate.
class PdfWriteRequest {
  const PdfWriteRequest({
    required this.replyPort,
    required this.sourcePaths,
    required this.outputPath,
    required this.kind,
    required this.settings,
    required this.fontBytes,
  });

  final SendPort replyPort;
  final List<String> sourcePaths;
  final String outputPath;
  final PdfSourceKind kind;
  final PdfConversionSettings settings;
  final List<int> fontBytes;
}

/// What the isolate sends back.
///
/// A small closed set of plain values rather than `ConversionFailure` objects:
/// what survives a port intact is worth keeping obvious, and the mapping back
/// to a failure belongs on the side that has the localised copy anyway.
sealed class PdfWriteMessage {
  const PdfWriteMessage();
}

final class PdfWriteProgress extends PdfWriteMessage {
  const PdfWriteProgress({required this.done, required this.total});

  final int done;
  final int total;
}

final class PdfWriteDone extends PdfWriteMessage {
  const PdfWriteDone({required this.sizeInBytes});

  final int sizeInBytes;
}

/// Why a write stopped. One value per failure the UI can actually distinguish.
enum PdfWriteError { unsupportedCharacters, unreadableSource, engine }

final class PdfWriteFailed extends PdfWriteMessage {
  const PdfWriteFailed(this.error, {this.detail = ''});

  final PdfWriteError error;

  /// Offending characters for [PdfWriteError.unsupportedCharacters]; empty
  /// otherwise.
  final String detail;
}
