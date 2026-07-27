import 'package:flutter/material.dart';

import 'package:archonex/core/constants/app_radius.dart';
import 'package:archonex/core/constants/app_spacing.dart';
import 'package:archonex/project_files/features/converter_shared/domain/models/conversion_failure.dart';
import 'package:archonex/project_files/features/converter_shared/ui/mappers/conversion_failure_ui.dart';

/// A screen's only error surface: every failure is rendered here.
class ConversionErrorBanner extends StatelessWidget {
  const ConversionErrorBanner({required this.failure, super.key});

  static const double _padding = AppSpacing.lg;
  static const double _iconSize = 20;

  final ConversionFailure failure;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final bool isNeutral = failure.isNeutral;

    final Color background =
        isNeutral ? colors.surfaceContainerHighest : colors.errorContainer;
    final Color foreground =
        isNeutral ? colors.onSurfaceVariant : colors.onErrorContainer;

    return Container(
      padding: const EdgeInsets.all(_padding),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(failure.icon, size: _iconSize, color: foreground),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              failure.message(context),
              style: theme.textTheme.bodyMedium?.copyWith(color: foreground),
            ),
          ),
        ],
      ),
    );
  }
}
