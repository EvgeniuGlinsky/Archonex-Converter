import 'package:archonex_converter/core/constants/app_file_limits.dart';
import 'package:archonex_converter/project_files/features/converter_shared/domain/models/conversion_failure.dart';
import 'package:archonex_converter/project_files/features/converter_shared/domain/models/source_file.dart';
import 'package:archonex_converter/project_files/features/image_converter/domain/image_file_repo.dart';
import 'package:archonex_converter/project_files/features/image_converter/domain/models/image_format.dart';

/// What came back from the picker once the unusable entries were removed.
class PickedImages {
  const PickedImages({required this.accepted, this.rejection});

  const PickedImages.none() : accepted = const <SourceFile>[], rejection = null;

  final List<SourceFile> accepted;

  /// Set when part of the pick was dropped, so the screen can say so without
  /// throwing away the rest.
  final ConversionFailure? rejection;
}

/// Picks photos and refuses everything the converter cannot take.
///
/// The checks run on the picker metadata, so an oversized file is rejected
/// before a single byte is read.
///
/// A bad file in a pick of thirty does not fail the pick: the good ones are
/// kept and the count of the rest comes back as [PickedImages.rejection]. Only
/// a pick with nothing usable in it throws, and then it throws the reason the
/// first file was refused rather than a vague one.
class PickSourceImagesUseCase {
  const PickSourceImagesUseCase(this._repo);

  final ImageFileRepo _repo;

  /// [alreadySelected] is how many photos the screen is holding, so adding to
  /// an existing selection is bounded by the same ceiling as a fresh one.
  Future<PickedImages> call({int alreadySelected = 0}) async {
    final List<SourceFile> picked = await _repo.pickSources();

    if (picked.isEmpty) {
      // Dialog closed without a choice.
      return const PickedImages.none();
    }

    final int limit = AppFileLimits.maxBatchFiles;
    final int total = alreadySelected + picked.length;

    if (AppFileLimits.isBatchLimited && total > limit) {
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

    final int skipped = picked.length - accepted.length;

    return PickedImages(
      accepted: accepted,
      rejection:
          skipped == 0 ? null : FilesSkippedFailure(skippedCount: skipped),
    );
  }

  /// Why [file] cannot be used, or `null` when it can.
  ConversionFailure? _refuse(SourceFile file) {
    // The picker filter is advisory on every platform and absent entirely on
    // the unfiltered fallback, so the extension is what decides here.
    if (ImageFormat.fromExtension(file.extension) == null) {
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
}
