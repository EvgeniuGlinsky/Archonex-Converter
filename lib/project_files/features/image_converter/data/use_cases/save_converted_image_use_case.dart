import 'package:archonex/core/constants/app_file_limits.dart';
import 'package:archonex/project_files/features/converter_shared/domain/models/conversion_failure.dart';
import 'package:archonex/project_files/features/converter_shared/domain/models/converted_file.dart';
import 'package:archonex/project_files/features/converter_shared/domain/models/save_result.dart';
import 'package:archonex/project_files/features/image_converter/domain/image_file_repo.dart';

/// Hands one result to the platform: a save dialog, or a browser download.
///
/// Throws a `ConversionFailure` when the write fails.
class SaveConvertedImageUseCase {
  const SaveConvertedImageUseCase(this._repo);

  final ImageFileRepo _repo;

  Future<SaveResult> call(ConvertedFile file) async {
    // The input was checked at pick time, but an output can come out larger
    // than the source it came from — a compact JPG turned into TIFF, say.
    if (file.sizeInBytes > AppFileLimits.maxResultBytes) {
      throw ResultTooLargeToSaveFailure(actualBytes: file.sizeInBytes);
    }

    final String? location = await _repo.saveConverted(file);

    if (location != null) {
      return SaveResult(
        outcome: SaveOutcome.savedToLocation,
        location: location,
      );
    }

    // No location: the user backed out, unless the platform never reports one.
    return _repo.reportsSaveLocation
        ? const SaveResult.cancelled()
        : const SaveResult(outcome: SaveOutcome.downloadStarted);
  }
}
