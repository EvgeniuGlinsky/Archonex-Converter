import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:archonex/core/constants/app_strings.dart';
import 'package:archonex/core/widgets/app_screen_header.dart';
import 'package:archonex/core/widgets/app_screen_layout.dart';
import 'package:archonex/project_files/features/category_selection/domain/models/app_category.dart';
import 'package:archonex/project_files/features/category_selection/ui/bloc/category_selection_bloc.dart';
import 'package:archonex/project_files/features/category_selection/ui/mappers/app_category_ui.dart';
import 'package:archonex/project_files/features/category_selection/ui/widgets/category_grid.dart';

class CategorySelectionView extends StatelessWidget {
  const CategorySelectionView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppScreenLayout(
        header: const AppScreenHeader(
          title: AppStrings.categoryTitle,
          subtitle: AppStrings.categorySubtitle,
        ),
        body: BlocBuilder<CategorySelectionBloc, CategorySelectionState>(
          builder: (context, state) => CategoryGrid(
            categories: state.categories,
            onCategorySelected: (category) => _onCategorySelected(
              context,
              category,
            ),
          ),
        ),
      ),
    );
  }

  void _onCategorySelected(BuildContext context, AppCategory category) {
    context.goNamed(category.type.route.routeName);
  }
}
