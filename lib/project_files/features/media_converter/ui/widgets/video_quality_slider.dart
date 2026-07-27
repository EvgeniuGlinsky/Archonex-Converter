import 'package:flutter/material.dart';

import 'package:archonex/core/constants/app_spacing.dart';
import 'package:archonex/core/constants/app_strings.dart';
import 'package:archonex/project_files/features/media_converter/domain/models/conversion_quality.dart';

/// Normalised picture quality, from "smaller file" to "better quality".
///
/// The drag is held locally and only reported on release. Reporting every
/// intermediate value would push a settings change through the bloc dozens of
/// times per drag, and each one throws away the previous conversion result.
class VideoQualitySlider extends StatefulWidget {
  const VideoQualitySlider({
    required this.value,
    required this.isEnabled,
    required this.onChanged,
    super.key,
  });

  final int value;
  final bool isEnabled;
  final ValueChanged<int> onChanged;

  @override
  State<VideoQualitySlider> createState() => _VideoQualitySliderState();
}

class _VideoQualitySliderState extends State<VideoQualitySlider> {
  static const int _step = 5;

  late double _value = widget.value.toDouble();

  @override
  void didUpdateWidget(VideoQualitySlider oldWidget) {
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

    const int min = ConversionQuality.minVideoQuality;
    const int max = ConversionQuality.maxVideoQuality;

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
            Text(AppStrings.videoQualitySmaller, style: captionStyle),
            const SizedBox(width: AppSpacing.sm),
            Text(AppStrings.videoQualityBetter, style: captionStyle),
          ],
        ),
      ],
    );
  }
}
