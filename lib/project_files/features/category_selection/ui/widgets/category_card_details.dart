import 'package:flutter/material.dart';

import 'package:archonex/core/constants/app_spacing.dart';

/// Title and supporting text of a category card.
class CategoryCardDetails extends StatelessWidget {
  const CategoryCardDetails({
    required this.title,
    required this.subtitle,
    super.key,
  });

  static const int _subtitleMaxLines = 2;

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          title,
          maxLines: _subtitleMaxLines,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          subtitle,
          maxLines: _subtitleMaxLines,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
