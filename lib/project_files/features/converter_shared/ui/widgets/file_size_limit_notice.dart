import 'package:flutter/material.dart';

import 'package:archonex/core/constants/app_spacing.dart';

/// States a ceiling the screen enforces. Always visible, including before a
/// pick, because a limit discovered after the fact reads as a bug.
class FileSizeLimitNotice extends StatelessWidget {
  const FileSizeLimitNotice(this.text, {super.key});

  static const double _iconSize = 18;

  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color color = theme.colorScheme.onSurfaceVariant;

    return Row(
      children: <Widget>[
        Icon(Icons.info_outline_rounded, size: _iconSize, color: color),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}
