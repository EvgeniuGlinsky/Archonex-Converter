import 'package:flutter/material.dart';

import 'package:archonex/core/constants/app_durations.dart';
import 'package:archonex/core/constants/app_radius.dart';
import 'package:archonex/core/constants/app_spacing.dart';
import 'package:archonex/project_files/features/language_selection/domain/models/app_language.dart';

/// Single selectable language card.
class LanguageTile extends StatelessWidget {
  const LanguageTile({
    required this.language,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  static const double _borderWidth = 1.5;
  static const double _tilePadding = AppSpacing.lg;

  final AppLanguage language;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return AnimatedContainer(
      duration: AppDurations.shortAnimation,
      decoration: BoxDecoration(
        color: isSelected ? colors.primaryContainer : colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isSelected ? colors.primary : colors.outlineVariant,
          width: _borderWidth,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(_tilePadding),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        language.nativeLabel,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        language.label,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: isSelected ? colors.primary : colors.outline,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
