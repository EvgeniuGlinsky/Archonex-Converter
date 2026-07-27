import 'package:archonex_converter/core/constants/app_file_limits.dart';
import 'package:archonex_converter/project_files/features/converter_shared/domain/models/conversion_failure.dart';
import 'package:archonex_converter/project_files/features/converter_shared/domain/models/source_file.dart';
import 'package:archonex_converter/project_files/features/media_converter/domain/media_converter_repo.dart';
import 'package:archonex_converter/project_files/features/media_converter/domain/models/conversion_job.dart';
import 'package:archonex_converter/project_files/features/media_converter/domain/models/conversion_settings.dart';
import 'package:archonex_converter/project_files/features/media_converter/domain/models/media_format.dart';

/// Starts a conversion, re-checking the format pair and the upload ceiling.
///
/// The target grid only ever offers reachable formats and the pick use case
/// already rejects oversized files; both guards are repeated here so the engine
/// contract holds no matter how the call was assembled.
class ConvertMediaUseCase {
  const ConvertMediaUseCase(this._repo);

  final MediaConverterRepo _repo;

  ConversionJob call({
    required SourceFile source,
    required MediaFormat target,
    required ConversionSettings settings,
  }) {
    final MediaFormat? sourceFormat =
        MediaFormat.fromExtension(source.extension);

    if (sourceFormat == null) {
      throw UnsupportedFormatFailure(actualExtension: source.extension);
    }

    if (!sourceFormat.targets.contains(target)) {
      throw IncompatibleTargetFailure(
        sourceLabel: sourceFormat.label,
        targetLabel: target.label,
      );
    }

    if (source.sizeInBytes > AppFileLimits.maxUploadBytes) {
      throw FileTooLargeFailure(
        actualBytes: source.sizeInBytes,
        limitBytes: AppFileLimits.maxUploadBytes,
      );
    }

    return _repo.convert(source: source, target: target, settings: settings);
  }
}
