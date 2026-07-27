import 'package:flutter/material.dart';

import 'package:archonex/core/constants/app_radius.dart';

/// Tinted square holding the category glyph.
class CategoryCardIcon extends StatelessWidget {
  const CategoryCardIcon({required this.icon, super.key});

  static const double _boxSize = 48;
  static const double _iconSize = 24;

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Container(
      width: _boxSize,
      height: _boxSize,
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Icon(icon, size: _iconSize, color: colors.onPrimaryContainer),
    );
  }
}
