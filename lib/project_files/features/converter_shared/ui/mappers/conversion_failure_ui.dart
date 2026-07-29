import 'package:flutter/material.dart';

import 'package:archonex_converter/core/constants/app_file_limits.dart';
import 'package:archonex_converter/core/utils/file_size_formatter.dart';
import 'package:archonex_converter/l10n/app_localizations.dart';
import 'package:archonex_converter/project_files/features/converter_shared/domain/models/conversion_failure.dart';

/// Turns a failure into the copy and glyph shown by the error banner.
///
/// The switches are exhaustive on purpose: adding a failure without giving it
/// user facing copy will not compile.
extension ConversionFailureUi on ConversionFailure {
  String message(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return switch (this) {
      FileTooLargeFailure(:final int actualBytes) => l10n.fileTooLarge(
          FileSizeFormatter.format(actualBytes),
          AppFileLimits.maxUploadLabel,
        ),
      TooManyFilesFailure(:final int limitCount) =>
        l10n.tooManyFiles(limitCount),
      QuotaExceededFailure(:final int remaining, :final int requested) =>
        l10n.quotaExceededError(remaining, requested),
      FilesSkippedFailure(:final int skippedCount) =>
        l10n.filesSkipped(skippedCount),
      UnsupportedFormatFailure(:final String actualExtension) =>
        actualExtension.isEmpty
            ? l10n.unsupportedFormatNoExtension
            : l10n.unsupportedFormatExtension(actualExtension),
      IncompatibleTargetFailure(
        :final String sourceLabel,
        :final String targetLabel,
      ) =>
        l10n.incompatibleTarget(sourceLabel, targetLabel),
      NoAudioTrackFailure() => l10n.noAudioTrackError,
      CorruptSourceFailure() => l10n.corruptSourceError,
      PasswordProtectedFailure() => l10n.passwordProtectedError,
      UnsupportedCharactersFailure(:final String sample) =>
        l10n.unsupportedCharactersError(sample),
      MixedSourceKindsFailure() => l10n.mixedSourceKindsError,
      EmptyFileFailure() => l10n.emptyFileError,
      FileReadFailure() => l10n.fileReadError,
      ConversionUnsupportedFailure() => l10n.conversionUnsupportedError,
      ConversionEngineFailure() => l10n.conversionFailedError,
      ConversionCancelledFailure() => l10n.conversionCancelledError,
      InsufficientStorageFailure() => l10n.insufficientStorageError,
      SavePermissionDeniedFailure() => l10n.savePermissionDeniedError,
      // Two different sentences, because only one of the two paths knows a
      // ceiling. The pre-check in `SaveConverted*UseCase` measured the file and
      // compared it against `maxResultBytes`, so it can name both numbers; the
      // `OutOfMemoryError` `IoFileSaver` catches measured nothing and passed no
      // ceiling, because there is none — the device simply ran out. Naming one
      // anyway is how a phone came to report a file as over a 1 TB limit.
      ResultTooLargeToSaveFailure(:final int? actualBytes) => actualBytes == null
          ? l10n.resultTooLargeForMemory
          : l10n.resultTooLargeToSave(
              FileSizeFormatter.format(actualBytes),
              AppFileLimits.maxResultLabel,
            ),
      SaveFailure() => l10n.saveFailedError,
    };
  }

  IconData get icon => switch (this) {
        FileTooLargeFailure() => Icons.data_usage_rounded,
        TooManyFilesFailure() => Icons.filter_none_rounded,
        QuotaExceededFailure() => Icons.lock_outline_rounded,
        FilesSkippedFailure() => Icons.playlist_remove_rounded,
        UnsupportedFormatFailure() => Icons.extension_off_outlined,
        IncompatibleTargetFailure() => Icons.block_outlined,
        NoAudioTrackFailure() => Icons.volume_off_outlined,
        CorruptSourceFailure() => Icons.broken_image_outlined,
        PasswordProtectedFailure() => Icons.lock_person_outlined,
        UnsupportedCharactersFailure() => Icons.translate_rounded,
        MixedSourceKindsFailure() => Icons.shuffle_rounded,
        EmptyFileFailure() => Icons.description_outlined,
        FileReadFailure() => Icons.folder_off_outlined,
        ConversionUnsupportedFailure() => Icons.desktop_access_disabled_outlined,
        ConversionEngineFailure() => Icons.error_outline_rounded,
        ConversionCancelledFailure() => Icons.cancel_outlined,
        InsufficientStorageFailure() => Icons.sd_card_alert_outlined,
        SavePermissionDeniedFailure() => Icons.lock_outline_rounded,
        ResultTooLargeToSaveFailure() => Icons.data_usage_rounded,
        SaveFailure() => Icons.save_outlined,
      };

  /// Cancelling is expected behaviour, and so is dropping a few files out of a
  /// large pick or reaching the end of the free count, so all three are shown
  /// as notices rather than as errors. Nothing broke — the quota banner beside
  /// this one is what carries the way forward.
  bool get isNeutral =>
      this is ConversionCancelledFailure ||
      this is FilesSkippedFailure ||
      this is QuotaExceededFailure;
}
