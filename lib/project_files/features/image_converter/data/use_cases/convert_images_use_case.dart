import 'package:archonex_converter/core/constants/app_file_limits.dart';
import 'package:archonex_converter/project_files/features/converter_shared/domain/models/conversion_failure.dart';
import 'package:archonex_converter/project_files/features/converter_shared/domain/models/source_file.dart';
import 'package:archonex_converter/project_files/features/image_converter/domain/image_converter_repo.dart';
import 'package:archonex_converter/project_files/features/image_converter/domain/models/image_conversion_job.dart';
import 'package:archonex_converter/project_files/features/image_converter/domain/models/image_conversion_settings.dart';
import 'package:archonex_converter/project_files/features/image_converter/domain/models/image_format.dart';

/// Starts a batch, re-checking every guard the pick already applied.
///
/// The target grid only ever offers reachable formats and the pick use case
/// already rejects oversized files; both guards are repeated here so the engine
/// contract holds no matter how the call was assembled.
class ConvertImagesUseCase {
  const ConvertImagesUseCase(this._repo);

  final ImageConverterRepo _repo;

  ImageConversionJob call({
    required List<SourceFile> sources,
    required ImageFormat target,
    required ImageConversionSettings settings,
  }) {
    if (AppFileLimits.isBatchLimited &&
        sources.length > AppFileLimits.maxBatchFiles) {
      throw TooManyFilesFailure(
        actualCount: sources.length,
        limitCount: AppFileLimits.maxBatchFiles,
      );
    }

    for (final SourceFile source in sources) {
      _check(source, target);
    }

    return _repo.convert(sources: sources, target: target, settings: settings);
  }

  void _check(SourceFile source, ImageFormat target) {
    final ImageFormat? format = ImageFormat.fromExtension(source.extension);

    if (format == null) {
      throw UnsupportedFormatFailure(actualExtension: source.extension);
    }

    if (!format.targets.contains(target)) {
      throw IncompatibleTargetFailure(
        sourceLabel: format.label,
        targetLabel: target.label,
      );
    }

    if (source.sizeInBytes > AppFileLimits.maxUploadBytes) {
      throw FileTooLargeFailure(
        actualBytes: source.sizeInBytes,
        limitBytes: AppFileLimits.maxUploadBytes,
      );
    }
  }
}
