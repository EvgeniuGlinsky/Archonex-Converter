import 'package:archonex_converter/core/constants/app_file_limits.dart';
import 'package:archonex_converter/project_files/features/converter_shared/domain/models/conversion_failure.dart';
import 'package:archonex_converter/project_files/features/converter_shared/domain/models/source_file.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/domain/models/pdf_format.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/domain/pdf_file_repo.dart';

/// What came back from the picker once the unusable entries were removed.
class PickedPdfSources {
  const PickedPdfSources({required this.accepted, this.rejection});

  const PickedPdfSources.none()
      : accepted = const <SourceFile>[],
        rejection = null;

  final List<SourceFile> accepted;

  /// Set when part of the pick was dropped, so the screen can say so without
  /// throwing away the rest.
  final ConversionFailure? rejection;
}

/// Picks sources and refuses everything the converter cannot take.
///
/// Follows the image converter's rule that a bad file in a large pick does not
/// fail the pick, with one addition of its own: the batch has to be all one
/// kind. Pictures and a PDF in the same run would have to travel in opposite
/// directions, so a mixed pick is refused outright rather than half accepted —
/// there is no sensible half of it to keep.
class PickPdfSourcesUseCase {
  const PickPdfSourcesUseCase(this._repo);

  final PdfFileRepo _repo;

  /// [alreadySelected] is what the screen is already holding, and
  /// [existingKind] the kind it settled on, so an addition is bounded by the
  /// same ceiling and the same direction as the pick that started it.
  Future<PickedPdfSources> call({
    int alreadySelected = 0,
    PdfSourceKind? existingKind,
  }) async {
    final List<SourceFile> picked = await _repo.pickSources();

    if (picked.isEmpty) {
      // Dialog closed without a choice.
      return const PickedPdfSources.none();
    }

    final int limit = AppFileLimits.maxBatchFiles;
    final int total = alreadySelected + picked.length;

    if (total > limit) {
      throw TooManyFilesFailure(actualCount: total, limitCount: limit);
    }

    final List<SourceFile> accepted = <SourceFile>[];
    ConversionFailure? firstRefusal;

    for (final SourceFile file in picked) {
      final ConversionFailure? refusal = _refuse(file);

      if (refusal == null) {
        accepted.add(file);
        continue;
      }

      firstRefusal ??= refusal;
    }

    if (firstRefusal != null && accepted.isEmpty) {
      throw firstRefusal;
    }

    _refuseMixedKinds(accepted, existingKind);

    final int skipped = picked.length - accepted.length;

    return PickedPdfSources(
      accepted: accepted,
      rejection:
          skipped == 0 ? null : FilesSkippedFailure(skippedCount: skipped),
    );
  }

  /// Why [file] cannot be used, or `null` when it can.
  ConversionFailure? _refuse(SourceFile file) {
    // The picker filter is advisory on every platform and absent entirely on
    // the unfiltered fallback, so the extension is what decides here.
    if (PdfFormat.fromExtension(file.extension) == null) {
      return UnsupportedFormatFailure(actualExtension: file.extension);
    }

    if (file.sizeInBytes <= 0) {
      return const EmptyFileFailure();
    }

    if (file.sizeInBytes > AppFileLimits.maxUploadBytes) {
      return FileTooLargeFailure(
        actualBytes: file.sizeInBytes,
        limitBytes: AppFileLimits.maxUploadBytes,
      );
    }

    return null;
  }

  /// Throws when [accepted] cannot join [existingKind] as one direction.
  void _refuseMixedKinds(
    List<SourceFile> accepted,
    PdfSourceKind? existingKind,
  ) {
    final List<PdfFormat> formats = <PdfFormat>[
      for (final SourceFile file in accepted)
        if (PdfFormat.fromExtension(file.extension) case final PdfFormat format)
          format,
    ];

    final PdfSourceKind? kind = PdfFormat.sharedKind(formats);

    if (kind == null || (existingKind != null && kind != existingKind)) {
      throw const MixedSourceKindsFailure();
    }
  }
}
