import 'package:archonex_converter/project_files/features/converter_shared/domain/models/conversion_failure.dart';
import 'package:archonex_converter/project_files/features/converter_shared/domain/models/converted_file.dart';
import 'package:archonex_converter/project_files/features/converter_shared/domain/models/source_file.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/domain/models/pdf_conversion_job.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/domain/models/pdf_conversion_settings.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/domain/models/pdf_conversion_update.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/domain/models/pdf_target.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/domain/pdf_converter_repo.dart';

/// Stands in on web, where there is no file system to write a document into.
class UnsupportedPdfConverterRepo implements PdfConverterRepo {
  const UnsupportedPdfConverterRepo();

  @override
  bool get isSupported => false;

  @override
  PdfConversionJob convert({
    required List<SourceFile> sources,
    required PdfTarget target,
    required PdfConversionSettings settings,
  }) =>
      const _UnsupportedPdfConversionJob();

  @override
  Future<void> discard(List<ConvertedFile> files) async {}
}

class _UnsupportedPdfConversionJob implements PdfConversionJob {
  const _UnsupportedPdfConversionJob();

  @override
  Stream<PdfConversionUpdate> get updates =>
      Stream<PdfConversionUpdate>.error(const ConversionUnsupportedFailure());

  @override
  Future<void> cancel() async {}
}
