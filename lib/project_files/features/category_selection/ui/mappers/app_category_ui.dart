import 'package:flutter/material.dart';

import 'package:archonex/core/router/app_route.dart';
import 'package:archonex/project_files/features/category_selection/domain/models/app_category.dart';

/// Presentation details of a category, kept out of the domain layer.
extension AppCategoryTypeUi on AppCategoryType {
  IconData get icon => switch (this) {
        AppCategoryType.fileConverters => Icons.swap_horiz_rounded,
        AppCategoryType.utilities => Icons.handyman_outlined,
        AppCategoryType.libraryApps => Icons.menu_book_outlined,
        AppCategoryType.newsApps => Icons.newspaper_outlined,
      };

  AppRoute get route => switch (this) {
        AppCategoryType.fileConverters => AppRoute.fileConverters,
        AppCategoryType.utilities => AppRoute.utilities,
        AppCategoryType.libraryApps => AppRoute.libraryApps,
        AppCategoryType.newsApps => AppRoute.newsApps,
      };
}
