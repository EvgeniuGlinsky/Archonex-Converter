import 'package:flutter/material.dart';

import 'package:archonex_converter/core/constants/app_spacing.dart';
import 'package:archonex_converter/l10n/app_localizations.dart';
import 'package:archonex_converter/project_files/features/converter_shared/domain/models/normalized_quality.dart';

/// Normalised quality, from "smaller file" to "better quality".
///
/// The drag is held locally and only reported on release. Reporting every
/// intermediate value would push a settings change through the bloc dozens of
/// times per drag, and each one throws away the previous conversion result.
class QualitySlider extends StatefulWidget {
  const QualitySlider({
    required this.value,
    required this.isEnabled,
    required this.onChanged,
    super.key,
  });

  final int value;
  final bool isEnabled;
  final ValueChanged<int> onChanged;

  @override
  State<QualitySlider> createState() => _QualitySliderState();
}

class _QualitySliderState extends State<QualitySlider> {
  static const int _step = 5;

  late double _value = widget.value.toDouble();

  @override
  void didUpdateWidget(QualitySlider oldWidget) {
    super.didUpdateWidget(oldWidget);

    // A preset change moves the value from outside the drag.
    if (widget.value != oldWidget.value) {
      _value = widget.value.toDouble();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle? captionStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    const int min = NormalizedQuality.min;
    const int max = NormalizedQuality.max;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Slider(
          value: _value,
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: (max - min) ~/ _step,
          label: '${_value.round()}',
          onChanged: widget.isEnabled
              ? (value) => setState(() => _value = value)
              : null,
          onChangeEnd: (value) => widget.onChanged(value.round()),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              AppLocalizations.of(context)!.qualitySmaller,
              style: captionStyle,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              AppLocalizations.of(context)!.qualityBetter,
              style: captionStyle,
            ),
          ],
        ),
      ],
    );
  }
}
