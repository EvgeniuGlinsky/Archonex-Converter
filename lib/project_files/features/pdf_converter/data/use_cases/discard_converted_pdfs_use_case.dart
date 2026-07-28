import 'package:archonex_converter/project_files/features/converter_shared/domain/models/converted_file.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/domain/pdf_converter_repo.dart';

/// Deletes the temporary files behind results the screen is dropping.
class DiscardConvertedPdfsUseCase {
  const DiscardConvertedPdfsUseCase(this._repo);

  final PdfConverterRepo _repo;

  Future<void> call(List<ConvertedFile> files) async {
    if (files.isEmpty) {
      return;
    }

    await _repo.discard(files);
  }
}
