import 'package:flutter/material.dart';

import 'package:archonex/core/constants/app_spacing.dart';

/// Label above one advanced control. Layout only, so every row lines up.
class AdvancedSettingRow extends StatelessWidget {
  const AdvancedSettingRow({
    required this.label,
    required this.child,
    super.key,
  });

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        child,
      ],
    );
  }
}
