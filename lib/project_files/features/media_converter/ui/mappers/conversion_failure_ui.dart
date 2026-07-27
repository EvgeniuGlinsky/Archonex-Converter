import 'package:flutter/material.dart';

import 'package:archonex/core/constants/app_strings.dart';
import 'package:archonex/core/utils/file_size_formatter.dart';
import 'package:archonex/project_files/features/media_converter/domain/models/conversion_failure.dart';

/// Turns a failure into the copy and glyph shown by the error banner.
///
/// The switches are exhaustive on purpose: adding a failure without giving it
/// user facing copy will not compile.
extension ConversionFailureUi on ConversionFailure {
  String get message => switch (this) {
        FileTooLargeFailure(:final int actualBytes) =>
          AppStrings.fileTooLarge(FileSizeFormatter.format(actualBytes)),
        UnsupportedFormatFailure(:final String actualExtension) =>
          AppStrings.unsupportedFormat(actualExtension),
        IncompatibleTargetFailure(
          :final String sourceLabel,
          :final String targetLabel,
        ) =>
          AppStrings.incompatibleTarget(sourceLabel, targetLabel),
        NoAudioTrackFailure() => AppStrings.noAudioTrackError,
        CorruptSourceFailure() => AppStrings.corruptSourceError,
        EmptyFileFailure() => AppStrings.emptyFileError,
        FileReadFailure() => AppStrings.fileReadError,
        ConversionUnsupportedFailure() => AppStrings.conversionUnsupportedError,
        ConversionEngineFailure() => AppStrings.conversionFailedError,
        ConversionCancelledFailure() => AppStrings.conversionCancelledError,
        InsufficientStorageFailure() => AppStrings.insufficientStorageError,
        SavePermissionDeniedFailure() => AppStrings.savePermissionDeniedError,
        ResultTooLargeToSaveFailure(:final int? actualBytes) =>
          AppStrings.resultTooLargeToSave(
            actualBytes == null
                ? AppStrings.unknownSize
                : FileSizeFormatter.format(actualBytes),
          ),
        SaveFailure() => AppStrings.saveFailedError,
      };

  IconData get icon => switch (this) {
        FileTooLargeFailure() => Icons.data_usage_rounded,
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

  /// Cancelling is expected behaviour, so it is shown as a notice rather than
  /// as an error.
  bool get isNeutral => this is ConversionCancelledFailure;
}
