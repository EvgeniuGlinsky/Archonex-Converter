import 'package:archonex_converter/project_files/features/converter_shared/domain/models/converted_file.dart';
import 'package:archonex_converter/project_files/features/converter_shared/domain/models/source_file.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/domain/models/pdf_conversion_job.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/domain/models/pdf_conversion_settings.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/domain/models/pdf_target.dart';

/// The engine behind the PDF converter.
abstract interface class PdfConverterRepo {
  /// `false` where no engine ships, which is what the screen says up front
  /// instead of failing once a file has been picked.
  bool get isSupported;

  /// Starts a run. The direction is implied by [target] — see
  /// `PdfTarget.mergesBatch`.
  PdfConversionJob convert({
    required List<SourceFile> sources,
    required PdfTarget target,
    required PdfConversionSettings settings,
  });

  /// Deletes the temporary files behind [files].
  Future<void> discard(List<ConvertedFile> files);
}
