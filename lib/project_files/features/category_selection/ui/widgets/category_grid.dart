import 'package:flutter/material.dart';

import 'package:archonex/core/constants/app_breakpoints.dart';
import 'package:archonex/core/constants/app_spacing.dart';
import 'package:archonex/project_files/features/category_selection/domain/models/app_category.dart';
import 'package:archonex/project_files/features/category_selection/ui/widgets/category_card.dart';

typedef CategorySelectedCallback = void Function(AppCategory category);

/// Responsive grid of category cards.
class CategoryGrid extends StatelessWidget {
  const CategoryGrid({
    required this.categories,
    required this.onCategorySelected,
    super.key,
  });

  final List<AppCategory> categories;
  final CategorySelectedCallback onCategorySelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final _GridConfig config = _GridConfig.forWidth(constraints.maxWidth);

        return GridView.builder(
          itemCount: categories.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: config.columns,
            crossAxisSpacing: AppSpacing.lg,
            mainAxisSpacing: AppSpacing.lg,
            childAspectRatio: config.aspectRatio,
          ),
          itemBuilder: (context, index) {
            final AppCategory category = categories[index];

            return CategoryCard(
              category: category,
              onTap: () => onCategorySelected(category),
            );
          },
        );
      },
    );
  }
}

/// Column count and card proportions per available width.
class _GridConfig {
  const _GridConfig({required this.columns, required this.aspectRatio});

  factory _GridConfig.forWidth(double width) {
    if (width < AppBreakpoints.compact) {
      return const _GridConfig(columns: 1, aspectRatio: 2.4);
    }
    if (width < AppBreakpoints.medium) {
      return const _GridConfig(columns: 2, aspectRatio: 1.3);
    }
    return const _GridConfig(columns: 4, aspectRatio: 0.95);
  }

  final int columns;
  final double aspectRatio;
}
