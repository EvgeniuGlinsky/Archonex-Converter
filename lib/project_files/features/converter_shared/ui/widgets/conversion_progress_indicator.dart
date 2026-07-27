import 'package:flutter/material.dart';

import 'package:archonex/core/constants/app_radius.dart';
import 'package:archonex/core/constants/app_spacing.dart';
import 'package:archonex/l10n/app_localizations.dart';

/// Progress bar, percentage and the way out of a running conversion.
///
/// A `null` [progress] means the engine could not tell how much work there is,
/// so the bar runs indeterminate and the percentage is hidden rather than shown
/// as a made up number.
class ConversionProgressIndicator extends StatelessWidget {
  const ConversionProgressIndicator({
    required this.label,
    required this.progress,
    required this.onCancelPressed,
    super.key,
  });

  static const double _barHeight = 8;
  static const int _percentFactor = 100;

  /// What is happening right now, e.g. `Converting 3 of 10…`.
  final String label;

  final double? progress;
  final VoidCallback onCancelPressed;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final double? value = progress;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
            if (value != null)
              Text(
                '${(value * _percentFactor).round()}%',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: LinearProgressIndicator(value: value, minHeight: _barHeight),
        ),
        const SizedBox(height: AppSpacing.sm),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: onCancelPressed,
            child: Text(AppLocalizations.of(context)!.cancelLabel),
          ),
        ),
      ],
    );
  }
}
