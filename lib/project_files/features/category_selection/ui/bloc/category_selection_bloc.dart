import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:archonex/project_files/features/category_selection/data/use_cases/get_categories_use_case.dart';
import 'package:archonex/project_files/features/category_selection/domain/models/app_category.dart';

part 'category_selection_event.dart';
part 'category_selection_state.dart';

/// Supplies the categories shown on the hub screen.
class CategorySelectionBloc
    extends Bloc<CategorySelectionEvent, CategorySelectionState> {
  CategorySelectionBloc({required GetCategoriesUseCase getCategories})
      : _getCategories = getCategories,
        super(const CategorySelectionState()) {
    // restartable: a reload always supersedes the one in flight.
    on<CategorySelectionStarted>(_onStarted, transformer: restartable());
  }

  final GetCategoriesUseCase _getCategories;

  void _onStarted(
    CategorySelectionStarted event,
    Emitter<CategorySelectionState> emit,
  ) {
    emit(
      state.copyWith(
        status: CategorySelectionStatus.ready,
        categories: _getCategories(),
      ),
    );
  }
}
