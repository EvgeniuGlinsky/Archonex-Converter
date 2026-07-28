import 'package:flutter/material.dart';

import 'package:archonex_converter/l10n/app_localizations.dart';
import 'package:archonex_converter/project_files/features/converter_shared/ui/widgets/format_badge.dart';
import 'package:archonex_converter/project_files/features/media_converter/domain/models/media_format.dart';

/// Presentation details of a format group, kept out of the domain layer.
extension MediaFormatKindUi on MediaFormatKind {
  IconData get icon => switch (this) {
        MediaFormatKind.video => Icons.movie_outlined,
        MediaFormatKind.animation => Icons.gif_box_outlined,
        MediaFormatKind.audio => Icons.graphic_eq_rounded,
      };

  /// Heading above the group inside the target picker.
  String title(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return switch (this) {
      MediaFormatKind.video => l10n.videoTargetsTitle,
      MediaFormatKind.animation => l10n.animationTargetsTitle,
      MediaFormatKind.audio => l10n.audioTargetsTitle,
    };
  }

  /// Colour a format pill borrows, so the three kinds stay distinguishable at
  /// a glance wherever a badge appears.
  FormatBadgeTone get badgeTone => switch (this) {
        MediaFormatKind.video => FormatBadgeTone.primary,
        MediaFormatKind.animation => FormatBadgeTone.secondary,
        MediaFormatKind.audio => FormatBadgeTone.tertiary,
      };
}
