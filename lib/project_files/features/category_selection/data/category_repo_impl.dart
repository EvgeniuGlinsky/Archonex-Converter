import 'package:archonex/core/constants/app_strings.dart';
import 'package:archonex/project_files/features/category_selection/domain/category_repo.dart';
import 'package:archonex/project_files/features/category_selection/domain/models/app_category.dart';

/// Static catalogue for now — becomes a remote or config driven source later.
class CategoryRepoImpl implements CategoryRepo {
  const CategoryRepoImpl();

  static const List<AppCategory> _categories = <AppCategory>[
    AppCategory(
      type: AppCategoryType.fileConverters,
      title: AppStrings.fileConverters,
      subtitle: AppStrings.fileConvertersSubtitle,
    ),
    AppCategory(
      type: AppCategoryType.utilities,
      title: AppStrings.utilities,
      subtitle: AppStrings.utilitiesSubtitle,
    ),
    AppCategory(
      type: AppCategoryType.libraryApps,
      title: AppStrings.libraryApps,
      subtitle: AppStrings.libraryAppsSubtitle,
    ),
    AppCategory(
      type: AppCategoryType.newsApps,
      title: AppStrings.newsApps,
      subtitle: AppStrings.newsAppsSubtitle,
    ),
  ];

  @override
  List<AppCategory> getCategories() => _categories;
}
