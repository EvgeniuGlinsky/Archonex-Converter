import 'package:archonex/core/constants/app_file_limits.dart';
import 'package:archonex/project_files/features/converter_shared/domain/models/conversion_failure.dart';
import 'package:archonex/project_files/features/converter_shared/domain/models/source_file.dart';
import 'package:archonex/project_files/features/media_converter/domain/media_file_repo.dart';
import 'package:archonex/project_files/features/media_converter/domain/models/media_format.dart';

/// Picks a source file and refuses everything the converter cannot take.
///
/// The checks run on the picker metadata, so an oversized file is rejected
/// before a single byte is read. Returns `null` when the user cancelled.
/// Throws a [ConversionFailure] when the pick is unusable.
class PickSourceFileUseCase {
  const PickSourceFileUseCase(this._repo);

  final MediaFileRepo _repo;

  Future<SourceFile?> call() async {
    final SourceFile? file = await _repo.pickSource();
    if (file == null) {
      return null;
    }

    // The picker filter is advisory on every platform and absent entirely on
    // the unfiltered fallback, so the extension is what decides here.
    if (MediaFormat.fromExtension(file.extension) == null) {
      throw UnsupportedFormatFailure(actualExtension: file.extension);
    }

    if (file.sizeInBytes <= 0) {
      throw const EmptyFileFailure();
    }

    if (file.sizeInBytes > AppFileLimits.maxUploadBytes) {
      throw FileTooLargeFailure(
        actualBytes: file.sizeInBytes,
        limitBytes: AppFileLimits.maxUploadBytes,
      );
    }

    return file;
  }
}
