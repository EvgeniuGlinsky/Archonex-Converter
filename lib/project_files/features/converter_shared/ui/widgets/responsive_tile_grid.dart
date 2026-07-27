import 'package:flutter/material.dart';

import 'package:archonex_converter/core/constants/app_breakpoints.dart';
import 'package:archonex_converter/core/constants/app_spacing.dart';

/// Lays tiles out in as many columns as the width allows.
///
/// The count comes from [LayoutBuilder] rather than `MediaQuery`: the screen
/// layout caps content at `AppBreakpoints.maxContentWidth` and pads it, so the
/// window width overstates the space available by a wide margin on desktop.
class ResponsiveTileGrid extends StatelessWidget {
  const ResponsiveTileGrid({required this.tiles, super.key});

  static const int compactColumns = 3;
  static const int mediumColumns = 4;
  static const int expandedColumns = 6;

  static const double _tileAspectRatio = 1.5;
  static const double _spacing = AppSpacing.sm;

  final List<Widget> tiles;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => GridView.count(
        crossAxisCount: columnsFor(constraints.maxWidth),
        childAspectRatio: _tileAspectRatio,
        crossAxisSpacing: _spacing,
        mainAxisSpacing: _spacing,
        // The body is already a ListView; this one only measures itself.
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: tiles,
      ),
    );
  }

  static int columnsFor(double width) {
    if (width < AppBreakpoints.compact) {
      return compactColumns;
    }
    if (width < AppBreakpoints.medium) {
      return mediumColumns;
    }

    return expandedColumns;
  }
}
