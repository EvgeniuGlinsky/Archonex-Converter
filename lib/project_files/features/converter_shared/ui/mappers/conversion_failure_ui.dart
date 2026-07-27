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
      EmptyFileFailure() => l10n.emptyFileError,
      FileReadFailure() => l10n.fileReadError,
      ConversionUnsupportedFailure() => l10n.conversionUnsupportedError,
      ConversionEngineFailure() => l10n.conversionFailedError,
      ConversionCancelledFailure() => l10n.conversionCancelledError,
      InsufficientStorageFailure() => l10n.insufficientStorageError,
      SavePermissionDeniedFailure() => l10n.savePermissionDeniedError,
      ResultTooLargeToSaveFailure(:final int? actualBytes) =>
        l10n.resultTooLargeToSave(
          actualBytes == null
              ? l10n.unknownSize
              : FileSizeFormatter.format(actualBytes),
          AppFileLimits.maxUploadLabel,
        ),
      SaveFailure() => l10n.saveFailedError,
    };
  }

  IconData get icon => switch (this) {
        FileTooLargeFailure() => Icons.data_usage_rounded,
        TooManyFilesFailure() => Icons.filter_none_rounded,
        FilesSkippedFailure() => Icons.playlist_remove_rounded,
        UnsupportedFormatFailure() => Icons.extension_off_outlined,
        IncompatibleTargetFailure() => Icons.block_outlined,
        NoAudioTrackFailure() => Icons.volume_off_outlined,
        CorruptSourceFailure() => Icons.broken_image_outlined,
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
  /// large pick, so both are shown as notices rather than as errors.
  bool get isNeutral =>
      this is ConversionCancelledFailure || this is FilesSkippedFailure;
}
