import 'package:archonex_converter/core/constants/app_file_limits.dart';
import 'package:archonex_converter/project_files/features/converter_shared/domain/models/conversion_failure.dart';
import 'package:archonex_converter/project_files/features/converter_shared/domain/models/converted_file.dart';
import 'package:archonex_converter/project_files/features/converter_shared/domain/models/save_result.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/domain/pdf_file_repo.dart';

/// Writes one result to wherever the user points.
class SaveConvertedPdfUseCase {
  const SaveConvertedPdfUseCase(this._repo);

  final PdfFileRepo _repo;

  Future<SaveResult> call(ConvertedFile file) async {
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
