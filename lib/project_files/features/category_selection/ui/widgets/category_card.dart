import 'package:flutter/material.dart';

import 'package:archonex/core/constants/app_radius.dart';
import 'package:archonex/core/constants/app_spacing.dart';
import 'package:archonex/project_files/features/category_selection/domain/models/app_category.dart';
import 'package:archonex/project_files/features/category_selection/ui/mappers/app_category_ui.dart';
import 'package:archonex/project_files/features/category_selection/ui/widgets/category_card_details.dart';
import 'package:archonex/project_files/features/category_selection/ui/widgets/category_card_icon.dart';

/// Tappable card representing one product category.
///
/// Stacks the icon above the text on tall tiles and places it beside the text
/// on the wide tiles used by the single column phone layout.
class CategoryCard extends StatelessWidget {
  const CategoryCard({
    required this.category,
    required this.onTap,
    super.key,
  });

  static const double _cardPadding = AppSpacing.xl;

  final AppCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(_cardPadding),
          child: LayoutBuilder(builder: _buildContent),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, BoxConstraints constraints) {
    final Widget icon = CategoryCardIcon(icon: category.type.icon);
    final Widget details = CategoryCardDetails(
      title: category.title,
      subtitle: category.subtitle,
    );

    if (constraints.maxWidth > constraints.maxHeight) {
      return Row(
        children: <Widget>[
          icon,
          const SizedBox(width: AppSpacing.lg),
          Expanded(child: details),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[icon, details],
    );
  }
}
