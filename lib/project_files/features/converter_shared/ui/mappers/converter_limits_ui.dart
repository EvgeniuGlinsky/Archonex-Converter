import 'package:flutter/widgets.dart';

import 'package:archonex_converter/core/constants/app_file_limits.dart';
import 'package:archonex_converter/l10n/app_localizations.dart';

/// The one line each converter shows about the ceilings it enforces.
///
/// Every screen used to phrase this itself, and each one named a different
/// subset — a count, a size, or both. Once a platform stops enforcing one of
/// them that is how a screen keeps promising a limit that is no longer there,
/// which reads as a bug in exactly the way `FileSizeLimitNotice` exists to
/// prevent. Deriving it in one place is the same rule the bloc states follow:
/// a condition two widgets work out separately is a condition they will
/// eventually disagree about.
///
/// Where nothing bounds what comes in, the line names the one ceiling that is
/// left, which on iOS is saving. Where nothing bounds either side — Android and
/// desktop both — it returns `null` and the screen shows no line at all, because
/// the honest alternative was announcing a terabyte, and a limit stated as a
/// number nobody will reach reads as a limit rather than as its absence.
class ConverterLimitsUi {
  const ConverterLimitsUi._();

  /// Whether anything about the incoming file is worth announcing at all.
  static bool get _announcesIncoming =>
      AppFileLimits.limitsSourceSize || AppFileLimits.isBatchLimited;

  /// The media converter, which takes one file at a time and so never has a
  /// count to state. `null` when there is no ceiling to name.
  static String? forMedia(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return AppFileLimits.limitsSourceSize
        ? l10n.maxFileSizeNotice(AppFileLimits.maxUploadLabel)
        : _savingOnly(l10n);
  }

  static String? forImages(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return _announcesIncoming
        ? l10n.imageLimitsNotice(
            AppFileLimits.maxBatchFiles,
            AppFileLimits.maxUploadLabel,
          )
        : _savingOnly(l10n);
  }

  static String? forPdf(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return _announcesIncoming
        ? l10n.pdfSourcesNotice(
            AppFileLimits.maxBatchFiles,
            AppFileLimits.maxUploadLabel,
          )
        : _savingOnly(l10n);
  }

  /// The empty-state line on the media converter.
  ///
  /// These three repeat the notices above rather than share their wording,
  /// because an empty picker is where the limit is worth restating and a full
  /// one is not. What they must not do is disagree with them.
  static String mediaEmptyHint(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return AppFileLimits.limitsSourceSize
        ? l10n.chooseFileHint(AppFileLimits.maxUploadLabel)
        : l10n.chooseFileHintUnlimited;
  }

  static String imagesEmptyHint(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return AppFileLimits.isBatchLimited
        ? l10n.noPhotosHint(AppFileLimits.maxBatchFiles)
        : l10n.noPhotosHintUnlimited;
  }

  static String pdfEmptyHint(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return AppFileLimits.isBatchLimited
        ? l10n.noFilesHint(AppFileLimits.maxBatchFiles)
        : l10n.noFilesHintUnlimited;
  }

  /// The line for a platform that bounds what it saves but not what it takes in.
  ///
  /// **No platform is in that position today** — Android was, until saving went
  /// through a picked folder, and iOS bounds both sides and so announces the
  /// incoming number instead. Kept rather than deleted because it is the one
  /// branch that expresses why `AppFileLimits` carries two numbers instead of
  /// one, and a save path that regresses would otherwise need this copy written
  /// again in three languages. It returning `null` is the normal case now, not a
  /// fallback.
  static String? _savingOnly(AppLocalizations l10n) =>
      AppFileLimits.limitsResultSize
          ? l10n.maxResultSizeNotice(AppFileLimits.maxResultLabel)
          : null;
}
