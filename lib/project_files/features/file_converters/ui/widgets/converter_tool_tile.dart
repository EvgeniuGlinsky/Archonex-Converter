import 'package:flutter/material.dart';

import 'package:archonex/core/constants/app_radius.dart';
import 'package:archonex/core/constants/app_spacing.dart';
import 'package:archonex/core/constants/app_strings.dart';
import 'package:archonex/project_files/features/file_converters/domain/models/converter_tool.dart';
import 'package:archonex/project_files/features/file_converters/ui/mappers/converter_tool_ui.dart';

/// One converter row. A `null` [onTap] renders the upcoming state: dimmed copy
/// and a "Soon" badge instead of the chevron.
class ConverterToolTile extends StatelessWidget {
  const ConverterToolTile({
    required this.tool,
    required this.onTap,
    super.key,
  });

  static const double _tilePadding = AppSpacing.lg;
  static const double _iconBoxSize = 44;
  static const double _iconSize = 22;
  static const double _disabledOpacity = 0.55;

  final ConverterTool tool;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final bool isEnabled = onTap != null;

    return Opacity(
      opacity: isEnabled ? 1 : _disabledOpacity,
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Padding(
            padding: const EdgeInsets.all(_tilePadding),
            child: Row(
              children: <Widget>[
                _Icon(icon: tool.type.icon),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: _Details(title: tool.title, subtitle: tool.subtitle),
                ),
                const SizedBox(width: AppSpacing.md),
                if (isEnabled)
                  Icon(Icons.chevron_right_rounded, color: colors.outline)
                else
                  const _ComingSoonBadge(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Icon extends StatelessWidget {
  const _Icon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Container(
      width: ConverterToolTile._iconBoxSize,
      height: ConverterToolTile._iconBoxSize,
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Icon(
        icon,
        size: ConverterToolTile._iconSize,
        color: colors.onPrimaryContainer,
      ),
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({required this.title, required this.subtitle});

  static const int _maxLines = 2;

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          title,
          maxLines: _maxLines,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          subtitle,
          maxLines: _maxLines,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _ComingSoonBadge extends StatelessWidget {
  const _ComingSoonBadge();

  static const EdgeInsets _padding = EdgeInsets.symmetric(
    horizontal: AppSpacing.sm,
    vertical: AppSpacing.xs,
  );

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Container(
      padding: _padding,
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        AppStrings.comingSoonBadge,
        style: theme.textTheme.labelSmall?.copyWith(
          color: colors.onSecondaryContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
