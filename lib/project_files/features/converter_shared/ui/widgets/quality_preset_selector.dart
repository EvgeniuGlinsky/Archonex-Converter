import 'package:flutter/material.dart';

import 'package:archonex/core/constants/app_spacing.dart';
import 'package:archonex/l10n/app_localizations.dart';
import 'package:archonex/project_files/features/converter_shared/ui/widgets/section_title.dart';

/// The quality steps a converter offers, plus a line saying what the current
/// one costs.
///
/// Generic over the preset enum: every converter has its own idea of what
/// "compact" means, but they all present the choice the same way.
class QualityPresetSelector<T> extends StatelessWidget {
  const QualityPresetSelector({
    required this.options,
    required this.selected,
    required this.labelOf,
    required this.hint,
    required this.isEnabled,
    required this.onChanged,
    super.key,
  });

  final List<T> options;
  final T selected;
  final String Function(T option) labelOf;

  /// One line under the selector describing [selected].
  final String hint;

  final bool isEnabled;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SectionTitle(AppLocalizations.of(context)!.qualityTitle),
        const SizedBox(height: AppSpacing.sm),
        SegmentedButton<T>(
          segments: options
              .map(
                (option) => ButtonSegment<T>(
                  value: option,
                  label: Text(labelOf(option)),
                ),
              )
              .toList(),
          selected: <T>{selected},
          showSelectedIcon: false,
          onSelectionChanged:
              isEnabled ? (selection) => onChanged(selection.first) : null,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          hint,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
