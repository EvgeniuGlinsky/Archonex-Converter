import 'package:archonex/project_files/features/category_selection/domain/models/app_category.dart';

/// Contract for reading the product categories.
abstract interface class CategoryRepo {
  List<AppCategory> getCategories();
}
