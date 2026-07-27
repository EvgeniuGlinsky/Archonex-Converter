import 'package:flutter/material.dart';

import 'package:archonex/core/constants/app_spacing.dart';
import 'package:archonex/core/constants/app_strings.dart';
import 'package:archonex/project_files/features/media_converter/domain/models/conversion_quality.dart';
import 'package:archonex/project_files/features/media_converter/ui/mappers/conversion_quality_ui.dart';
import 'package:archonex/project_files/features/media_converter/ui/widgets/section_title.dart';

typedef ConversionQualityCallback = void Function(ConversionQuality quality);

/// The three quality steps, plus a line saying what the current one costs.
class QualityPresetSelector extends StatelessWidget {
  const QualityPresetSelector({
    required this.selected,
    required this.isEnabled,
    required this.onChanged,
    super.key,
  });

  final ConversionQuality selected;
  final bool isEnabled;
  final ConversionQualityCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SectionTitle(AppStrings.qualityTitle),
        const SizedBox(height: AppSpacing.sm),
        SegmentedButton<ConversionQuality>(
          segments: ConversionQuality.values
              .map(
                (quality) => ButtonSegment<ConversionQuality>(
                  value: quality,
                  label: Text(quality.label),
                ),
              )
              .toList(),
          selected: <ConversionQuality>{selected},
          showSelectedIcon: false,
          onSelectionChanged:
              isEnabled ? (selection) => onChanged(selection.first) : null,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          selected.hint,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
