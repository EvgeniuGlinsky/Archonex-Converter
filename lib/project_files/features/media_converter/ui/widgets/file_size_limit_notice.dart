import 'package:flutter/material.dart';

import 'package:archonex/core/constants/app_spacing.dart';
import 'package:archonex/core/constants/app_strings.dart';

/// States the upload ceiling. Always visible, including before a pick.
class FileSizeLimitNotice extends StatelessWidget {
  const FileSizeLimitNotice({super.key});

  static const double _iconSize = 18;

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
            AppStrings.maxFileSizeNotice,
            style: theme.textTheme.bodyMedium?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}
