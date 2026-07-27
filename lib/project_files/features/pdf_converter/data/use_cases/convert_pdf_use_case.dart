import 'package:archonex_converter/core/constants/app_file_limits.dart';
import 'package:archonex_converter/project_files/features/converter_shared/domain/models/conversion_failure.dart';
import 'package:archonex_converter/project_files/features/converter_shared/domain/models/source_file.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/domain/models/pdf_conversion_job.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/domain/models/pdf_conversion_settings.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/domain/models/pdf_format.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/domain/models/pdf_target.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/domain/pdf_converter_repo.dart';

/// Starts a run after re-checking everything the screen should already have
/// enforced.
///
/// The guards duplicate the picker's on purpose, the same way the image
/// converter's do: the engine contract holds no matter how the call was
/// assembled.
class ConvertPdfUseCase {
  const ConvertPdfUseCase(this._repo);

  final PdfConverterRepo _repo;

  PdfConversionJob call({
    required List<SourceFile> sources,
    required PdfTarget target,
    required PdfConversionSettings settings,
  }) {
    if (sources.isEmpty) {
      throw const FileReadFailure();
    }

    final List<PdfFormat> formats = <PdfFormat>[];

    for (final SourceFile source in sources) {
      final PdfFormat? format = PdfFormat.fromExtension(source.extension);

      if (format == null) {
        throw UnsupportedFormatFailure(actualExtension: source.extension);
      }

      if (source.sizeInBytes > AppFileLimits.maxUploadBytes) {
        throw FileTooLargeFailure(
          actualBytes: source.sizeInBytes,
          limitBytes: AppFileLimits.maxUploadBytes,
        );
      }

      formats.add(format);
    }

    if (sources.length > AppFileLimits.maxBatchFiles) {
      throw TooManyFilesFailure(
        actualCount: sources.length,
        limitCount: AppFileLimits.maxBatchFiles,
      );
    }

    final PdfSourceKind? kind = PdfFormat.sharedKind(formats);

    if (kind == null) {
      throw const MixedSourceKindsFailure();
    }

    if (!PdfTarget.targetsFor(kind).contains(target)) {
      throw IncompatibleTargetFailure(
        sourceLabel: formats.first.label,
        targetLabel: target.label,
      );
    }

    return _repo.convert(
      sources: sources,
      target: target,
      settings: settings.prunedFor(target),
    );
  }
}
