import 'package:archonex_converter/core/constants/app_file_limits.dart';
import 'package:archonex_converter/project_files/features/converter_shared/domain/models/conversion_failure.dart';
import 'package:archonex_converter/project_files/features/converter_shared/domain/models/converted_file.dart';
import 'package:archonex_converter/project_files/features/converter_shared/domain/models/save_result.dart';
import 'package:archonex_converter/project_files/features/media_converter/domain/media_file_repo.dart';

/// Hands the result to the platform: a save dialog, or a browser download.
///
/// Throws a `ConversionFailure` when the write fails.
class SaveConvertedFileUseCase {
  const SaveConvertedFileUseCase(this._repo);

  final MediaFileRepo _repo;

  Future<SaveResult> call(ConvertedFile file) async {
    // The input was checked at pick time, but an output can come out larger
    // than the source it came from — a compact MP4 turned into WAV, say. On
    // mobile the whole result has to be resident to be saved, so an unchecked
    // one is the shortest path to an out of memory kill.
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
