import 'package:archonex_converter/core/constants/app_file_limits.dart';
import 'package:archonex_converter/project_files/features/converter_shared/domain/models/conversion_failure.dart';
import 'package:archonex_converter/project_files/features/converter_shared/domain/models/converted_file.dart';
import 'package:archonex_converter/project_files/features/converter_shared/domain/models/save_result.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/domain/pdf_file_repo.dart';

/// Writes every result into one chosen folder.
class SaveAllConvertedPdfsUseCase {
  const SaveAllConvertedPdfsUseCase(this._repo);

  final PdfFileRepo _repo;

  Future<SaveResult> call(List<ConvertedFile> files) {
    // Per file, not on the sum: the ceiling is about what has to be resident
    // for one save, and they happen one at a time.
    for (final ConvertedFile file in files) {
      if (file.sizeInBytes > AppFileLimits.maxResultBytes) {
        throw ResultTooLargeToSaveFailure(actualBytes: file.sizeInBytes);
      }
    }

    return _repo.saveAllConverted(files);
  }
}
