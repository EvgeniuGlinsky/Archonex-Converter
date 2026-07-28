import 'package:archonex_converter/project_files/features/converter_shared/domain/models/conversion_failure.dart';
import 'package:archonex_converter/project_files/features/converter_shared/domain/models/converted_file.dart';
import 'package:archonex_converter/project_files/features/converter_shared/domain/models/save_result.dart';
import 'package:archonex_converter/project_files/features/converter_shared/domain/models/source_file.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/domain/pdf_file_repo.dart';

/// Stands in on web, where nothing here can run.
class UnsupportedPdfFileRepo implements PdfFileRepo {
  const UnsupportedPdfFileRepo();

  @override
  bool get reportsSaveLocation => false;

  @override
  Future<List<SourceFile>> pickSources() async =>
      throw const ConversionUnsupportedFailure();

  @override
  Future<List<int>> readSource(SourceFile file) async =>
      throw const ConversionUnsupportedFailure();

  @override
  Future<String?> saveConverted(ConvertedFile file) async =>
      throw const ConversionUnsupportedFailure();

  @override
  Future<SaveResult> saveAllConverted(List<ConvertedFile> files) async =>
      throw const ConversionUnsupportedFailure();
}
