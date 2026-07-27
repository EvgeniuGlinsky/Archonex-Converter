import 'package:archonex/core/constants/app_file_limits.dart';

/// Single place for user facing copy.
///
/// Keeping the strings here means swapping in a real localization delegate
/// later touches one file instead of every widget.
class AppStrings {
  const AppStrings._();

  static const String appName = 'Archonex';
  static const String appTagline = 'All our products, one place';

  // Language selection
  static const String languageTitle = 'Choose your language';
  static const String languageSubtitle =
      'Select the language you want to use in the app.';
  static const String continueLabel = 'Continue';

  // Category selection
  static const String categoryTitle = 'Explore categories';
  static const String categorySubtitle =
      'Pick a category to browse the products inside it.';

  // Categories
  static const String fileConverters = 'File Converters';
  static const String fileConvertersSubtitle = 'Move files between formats';
  static const String utilities = 'Utilities';
  static const String utilitiesSubtitle = 'Small tools for everyday tasks';
  static const String libraryApps = 'Library Applications';
  static const String libraryAppsSubtitle = 'Collect, organise and read';
  static const String newsApps = 'News Applications';
  static const String newsAppsSubtitle = 'Stay up to date with your feeds';

  // File converters catalogue
  static const String fileConvertersTitle = 'File converters';
  static const String fileConvertersScreenSubtitle =
      'Pick a converter to get started. More are on the way.';
  static const String comingSoonBadge = 'Soon';

  static const String mediaConverter = 'Media converter';
  static const String mediaConverterSubtitle =
      'Video, audio and animated images';
  static const String imageConverter = 'Image converter';
  static const String imageConverterSubtitle = 'PNG, JPG and WebP';
  static const String documentConverter = 'Document converter';
  static const String documentConverterSubtitle = 'DOCX, PDF and TXT';

  // Media converter
  static const String mediaConverterTitle = 'Media converter';
  static const String mediaConverterScreenSubtitle =
      'Add a file, pick a format and convert it.';

  // Target picker. Format names themselves come from MediaFormat.label, so no
  // extension is ever spelled out twice.
  static const String convertToTitle = 'Convert to';
  static const String videoTargetsTitle = 'Video';
  static const String animationTargetsTitle = 'Animation';
  static const String audioTargetsTitle = 'Audio';
  static const String pickFileFirstHint =
      'Choose a file to see what it can be converted into.';

  static String convertToLabel(String format) => 'Convert to $format';

  // Quality
  static const String qualityTitle = 'Quality';
  static const String qualityHigh = 'High';
  static const String qualityBalanced = 'Balanced';
  static const String qualityCompact = 'Compact';
  static const String qualityHighHint = 'Best quality, largest file.';
  static const String qualityBalancedHint = 'Good quality at a sensible size.';
  static const String qualityCompactHint = 'Smallest file, lower quality.';

  // Advanced settings
  static const String advancedTitle = 'Advanced';
  static const String advancedHint = 'Override the preset for this file.';
  static const String resetToPresetLabel = 'Reset to preset';
  static const String resolutionLabel = 'Resolution';
  static const String frameRateLabel = 'Frame rate';
  static const String videoQualityLabel = 'Video quality';
  static const String videoQualitySmaller = 'Smaller file';
  static const String videoQualityBetter = 'Better quality';
  static const String audioBitrateLabel = 'Audio bitrate';
  static const String keepAudioLabel = 'Keep audio';
  static const String keepAudioHint = 'Turn off to produce a silent video.';

  // The ceiling differs per platform, so anything quoting it is a getter
  // rather than a constant — see AppFileLimits.
  static String get maxFileSizeNotice =>
      'Maximum file size: ${AppFileLimits.maxUploadLabel}';
  static const String chooseFileLabel = 'Choose file';
  static String get chooseFileHint =>
      'No file selected yet. Files up to ${AppFileLimits.maxUploadLabel} are '
      'accepted.';
  static const String removeFileLabel = 'Remove';
  static const String convertLabel = 'Convert';
  static const String convertingLabel = 'Converting…';
  static const String cancelLabel = 'Cancel';
  static const String downloadLabel = 'Download';
  static const String savingLabel = 'Saving…';
  static const String resultTitle = 'Converted file';

  static String savedTo(String location) => 'Saved to $location';
  static const String downloadStarted = 'Download started.';

  // Media converter failures
  static String fileTooLarge(String actualSize) =>
      'This file is $actualSize. The maximum allowed size is '
      '${AppFileLimits.maxUploadLabel}.';

  static String unsupportedFormat(String extension) => extension.isEmpty
      ? 'That file has no extension, so its format could not be detected.'
      : '.$extension files are not supported yet. Pick a video, audio or '
          'animated image file.';

  static String incompatibleTarget(String source, String target) =>
      '$source cannot be converted to $target.';

  static const String noAudioTrackError =
      'This file has no audio track, so there is nothing to extract.';
  static const String corruptSourceError =
      'This file could not be read as media. It may be damaged or use a codec '
      'the app does not support.';

  static const String unknownSize = 'too large';
  static const String emptyFileError = 'The selected file is empty.';
  static const String fileReadError =
      'Could not read the selected file. Try another one.';
  static const String conversionUnsupportedError =
      'Converting is not available on this platform yet. Use the Windows, '
      'macOS, Android or iOS app.';
  static const String conversionFailedError =
      'Conversion failed. Please try again.';
  static const String conversionCancelledError = 'Conversion cancelled.';
  static const String insufficientStorageError =
      'Not enough free space to store the result.';
  static const String savePermissionDeniedError =
      'Storage access was denied. Allow it in system settings and try again.';
  static String resultTooLargeToSave(String actualSize) =>
      'The converted file is $actualSize, over the '
      '${AppFileLimits.maxUploadLabel} limit on this platform. Try the Compact '
      'preset or a lower resolution.';
  static const String saveFailedError =
      'Could not save the file. Try a different location.';
}
