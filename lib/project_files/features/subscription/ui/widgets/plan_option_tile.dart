import 'package:flutter/material.dart';

import 'package:archonex_converter/core/constants/app_radius.dart';
import 'package:archonex_converter/core/constants/app_spacing.dart';

/// One selectable plan.
///
/// Presentation only: it is handed a period label and a price and knows
/// nothing about which plans exist or what a store is.
class PlanOptionTile extends StatelessWidget {
  const PlanOptionTile({
    required this.label,
    required this.priceLabel,
    required this.isSelected,
    required this.isEnabled,
    required this.onPressed,
    super.key,
  });

  static const double _selectedBorderWidth = 2;
  static const double _borderWidth = 1;
  static const double _disabledOpacity = 0.55;

  final String label;
  final String priceLabel;
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
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: isSelected ? colors.primary : colors.outlineVariant,
              width: isSelected ? _selectedBorderWidth : _borderWidth,
            ),
          ),
          child: Row(
            children: <Widget>[
              Icon(
                isSelected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: isSelected ? colors.primary : colors.outline,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: foreground,
                  ),
                ),
              ),
              Text(
                priceLabel,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w700,
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
