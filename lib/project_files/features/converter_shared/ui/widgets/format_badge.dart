import 'package:flutter/material.dart';

import 'package:archonex/core/constants/app_radius.dart';
import 'package:archonex/core/constants/app_spacing.dart';

/// Which container colour a badge borrows.
///
/// Named after the role rather than the colour so the theme stays the single
/// place a palette is decided.
enum FormatBadgeTone { primary, secondary, tertiary }

/// Pill carrying a format name, e.g. `MOV`.
///
/// Used by source cards, target tiles and result rows so a format always reads
/// the same way wherever it appears.
class FormatBadge extends StatelessWidget {
  const FormatBadge(this.label, {this.tone = FormatBadgeTone.primary, super.key});

  static const EdgeInsets _padding = EdgeInsets.symmetric(
    horizontal: AppSpacing.sm,
    vertical: AppSpacing.xs / 2,
  );

  final String label;
  final FormatBadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    final Color background = switch (tone) {
      FormatBadgeTone.primary => colors.primaryContainer,
      FormatBadgeTone.secondary => colors.secondaryContainer,
      FormatBadgeTone.tertiary => colors.tertiaryContainer,
    };
    final Color foreground = switch (tone) {
      FormatBadgeTone.primary => colors.onPrimaryContainer,
      FormatBadgeTone.secondary => colors.onSecondaryContainer,
      FormatBadgeTone.tertiary => colors.onTertiaryContainer,
    };

    return Container(
      padding: _padding,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
