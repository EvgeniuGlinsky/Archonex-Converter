part of 'category_selection_bloc.dart';

sealed class CategorySelectionEvent extends Equatable {
  const CategorySelectionEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

/// Loads the category catalogue.
final class CategorySelectionStarted extends CategorySelectionEvent {
  const CategorySelectionStarted();
}
