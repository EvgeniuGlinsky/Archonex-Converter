import 'package:equatable/equatable.dart';

/// Stable identifier of a product category.
///
/// Adding a category means adding a value here, a route in `AppRoute` and an
/// entry in the repository implementation.
enum AppCategoryType { fileConverters, utilities, libraryApps, newsApps }

/// A product category shown on the category selection screen.
class AppCategory extends Equatable {
  const AppCategory({
    required this.type,
    required this.title,
    required this.subtitle,
  });

  final AppCategoryType type;
  final String title;
  final String subtitle;

  @override
  List<Object?> get props => <Object?>[type, title, subtitle];
}
