import 'package:archonex/core/constants/app_file_limits.dart';
import 'package:archonex/project_files/features/converter_shared/domain/models/conversion_failure.dart';
import 'package:archonex/project_files/features/converter_shared/domain/models/converted_file.dart';
import 'package:archonex/project_files/features/converter_shared/domain/models/save_result.dart';
import 'package:archonex/project_files/features/image_converter/domain/image_file_repo.dart';

/// Writes a whole batch out, asking for a destination as few times as the
/// platform allows.
///
/// The ceiling is checked per file rather than on the total: files leave one at
/// a time, so what has to fit is the largest of them, not their sum.
class SaveAllConvertedImagesUseCase {
  const SaveAllConvertedImagesUseCase(this._repo);

  final ImageFileRepo _repo;

  Future<SaveResult> call(List<ConvertedFile> files) async {
    if (files.isEmpty) {
      return const SaveResult.cancelled();
    }

    for (final ConvertedFile file in files) {
      if (file.sizeInBytes > AppFileLimits.maxResultBytes) {
        throw ResultTooLargeToSaveFailure(actualBytes: file.sizeInBytes);
      }
    }

    return _repo.saveAllConverted(files);
  }
}
