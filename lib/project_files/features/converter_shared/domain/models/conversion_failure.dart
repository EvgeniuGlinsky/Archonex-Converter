/// Everything that can go wrong between picking a file and saving the result.
///
/// Shared by every converter, because the ways a conversion fails are a
/// property of the pipeline rather than of the media being pushed through it.
///
/// The hierarchy is sealed so the UI mapper switches exhaustively: a new
/// failure cannot be added without giving it user facing copy.
sealed class ConversionFailure implements Exception {
  const ConversionFailure();
}

/// The picked file is above the upload ceiling in `AppFileLimits`.
final class FileTooLargeFailure extends ConversionFailure {
  const FileTooLargeFailure({
    required this.actualBytes,
    required this.limitBytes,
  });

  final int actualBytes;
  final int limitBytes;
}

/// More files were picked at once than a single batch is allowed to carry.
final class TooManyFilesFailure extends ConversionFailure {
  const TooManyFilesFailure({
    required this.actualCount,
    required this.limitCount,
  });

  final int actualCount;
  final int limitCount;
}

/// Part of a multi file pick was dropped, and the rest was kept.
///
/// Carries a count rather than the individual reasons: a pick of thirty photos
/// with four rejects should say so in one line, not in four banners.
final class FilesSkippedFailure extends ConversionFailure {
  const FilesSkippedFailure({required this.skippedCount});

  final int skippedCount;
}

/// The picked file has an extension the converter knows nothing about.
final class UnsupportedFormatFailure extends ConversionFailure {
  const UnsupportedFormatFailure({required this.actualExtension});

  /// Extension of the picked file, without the leading dot.
  final String actualExtension;
}

/// The chosen target cannot be produced from the picked source, e.g. asking a
/// GIF for an MP3. Only reachable when state and UI disagree.
final class IncompatibleTargetFailure extends ConversionFailure {
  const IncompatibleTargetFailure({
    required this.sourceLabel,
    required this.targetLabel,
  });

  /// Upper case source format, e.g. `GIF`.
  final String sourceLabel;

  /// Upper case target format, e.g. `MP3`.
  final String targetLabel;
}

/// An audio only target was asked for, but the source carries no sound.
final class NoAudioTrackFailure extends ConversionFailure {
  const NoAudioTrackFailure();
}

/// FFmpeg could not make sense of the input at all.
final class CorruptSourceFailure extends ConversionFailure {
  const CorruptSourceFailure();
}

/// The picked file has no content.
final class EmptyFileFailure extends ConversionFailure {
  const EmptyFileFailure();
}

/// The platform refused to hand over the picked file.
final class FileReadFailure extends ConversionFailure {
  const FileReadFailure();
}

/// No conversion engine exists for the platform the app is running on.
final class ConversionUnsupportedFailure extends ConversionFailure {
  const ConversionUnsupportedFailure();
}

/// The conversion engine itself failed.
final class ConversionEngineFailure extends ConversionFailure {
  const ConversionEngineFailure();
}

/// The user stopped a running conversion.
final class ConversionCancelledFailure extends ConversionFailure {
  const ConversionCancelledFailure();
}

/// The device has no room for the result.
final class InsufficientStorageFailure extends ConversionFailure {
  const InsufficientStorageFailure();
}

/// The platform denied write access to the chosen location.
final class SavePermissionDeniedFailure extends ConversionFailure {
  const SavePermissionDeniedFailure();
}

/// The result is too large to hand to the platform's save dialog.
///
/// Only reachable on Android and iOS, where `file_picker` takes the bytes
/// rather than a path, so the whole file has to be resident at once. The
/// ceiling is the device's, not the app's — see the capacity probe.
final class ResultTooLargeToSaveFailure extends ConversionFailure {
  const ResultTooLargeToSaveFailure({this.actualBytes});

  /// Size of the result, when it is known. `null` when the platform ran out of
  /// memory before anything could be measured.
  final int? actualBytes;
}

/// Writing the result failed for any other reason.
final class SaveFailure extends ConversionFailure {
  const SaveFailure();
}
