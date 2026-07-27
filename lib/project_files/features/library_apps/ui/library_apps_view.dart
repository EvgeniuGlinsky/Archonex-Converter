import 'package:flutter/material.dart';

import 'package:archonex/core/constants/app_strings.dart';
import 'package:archonex/core/widgets/category_placeholder_view.dart';

class LibraryAppsView extends StatelessWidget {
  const LibraryAppsView({super.key});

  @override
  Widget build(BuildContext context) {
    return const CategoryPlaceholderView(title: AppStrings.libraryApps);
  }
}
