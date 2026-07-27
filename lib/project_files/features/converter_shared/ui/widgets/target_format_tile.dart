import 'package:flutter/material.dart';

import 'package:archonex/core/constants/app_radius.dart';
import 'package:archonex/core/constants/app_spacing.dart';

/// One selectable output format inside a target picker.
///
/// Presentation only: it is handed a label and a glyph, and knows nothing about
/// which formats exist or what they mean.
class TargetFormatTile extends StatelessWidget {
  const TargetFormatTile({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.isEnabled,
    required this.onPressed,
    super.key,
  });

  static const double _iconSize = 20;
  static const double _selectedBorderWidth = 2;
  static const double _borderWidth = 1;
  static const double _disabledOpacity = 0.55;

  final String label;
  final IconData icon;
  final bool isSelected;
  final bool isEnabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    final Color foreground =
        isSelected ? colors.onPrimaryContainer : colors.onSurface;

    final Widget tile = Material(
      color: isSelected ? colors.primaryContainer : colors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: isEnabled ? onPressed : null,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: isSelected ? colors.primary : colors.outlineVariant,
              width: isSelected ? _selectedBorderWidth : _borderWidth,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(icon, size: _iconSize, color: foreground),
              const SizedBox(height: AppSpacing.xs),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return isEnabled ? tile : Opacity(opacity: _disabledOpacity, child: tile);
  }
}
