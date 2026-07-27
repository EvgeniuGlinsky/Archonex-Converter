part of 'category_selection_bloc.dart';

enum CategorySelectionStatus { initial, ready }

final class CategorySelectionState extends Equatable {
  const CategorySelectionState({
    this.status = CategorySelectionStatus.initial,
    this.categories = const <AppCategory>[],
  });

  final CategorySelectionStatus status;
  final List<AppCategory> categories;

  CategorySelectionState copyWith({
    CategorySelectionStatus? status,
    List<AppCategory>? categories,
  }) {
    return CategorySelectionState(
      status: status ?? this.status,
      categories: categories ?? this.categories,
    );
  }

  @override
  List<Object?> get props => <Object?>[status, categories];
}
