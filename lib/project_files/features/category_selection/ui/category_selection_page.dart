import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:archonex/project_files/features/category_selection/data/category_repo_impl.dart';
import 'package:archonex/project_files/features/category_selection/data/use_cases/get_categories_use_case.dart';
import 'package:archonex/project_files/features/category_selection/ui/bloc/category_selection_bloc.dart';
import 'package:archonex/project_files/features/category_selection/ui/category_selection_view.dart';

/// Wires the category selection dependencies. No UI lives here.
class CategorySelectionPage extends StatelessWidget {
  const CategorySelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CategorySelectionBloc>(
      create: (_) => CategorySelectionBloc(
        getCategories: const GetCategoriesUseCase(CategoryRepoImpl()),
      )..add(const CategorySelectionStarted()),
      child: const CategorySelectionView(),
    );
  }
}
