import 'package:flutter/material.dart';

import 'package:archonex/core/constants/app_radius.dart';
import 'package:archonex/core/constants/app_spacing.dart';
import 'package:archonex/project_files/features/media_converter/domain/models/media_format.dart';

/// Pill carrying a format name, e.g. `MOV`.
///
/// Used by the source card, the target tiles and the result card so a format
/// always reads the same way wherever it appears.
class FormatBadge extends StatelessWidget {
  const FormatBadge(this.format, {super.key});

  static const EdgeInsets _padding = EdgeInsets.symmetric(
    horizontal: AppSpacing.sm,
    vertical: AppSpacing.xs / 2,
  );

  final MediaFormat format;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    final Color background = switch (format.kind) {
      MediaFormatKind.video => colors.primaryContainer,
      MediaFormatKind.animation => colors.secondaryContainer,
      MediaFormatKind.audio => colors.tertiaryContainer,
    };
    final Color foreground = switch (format.kind) {
      MediaFormatKind.video => colors.onPrimaryContainer,
      MediaFormatKind.animation => colors.onSecondaryContainer,
      MediaFormatKind.audio => colors.onTertiaryContainer,
    };

    return Container(
      padding: _padding,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        format.label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
