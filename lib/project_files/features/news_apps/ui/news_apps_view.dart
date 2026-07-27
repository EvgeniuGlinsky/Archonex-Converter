import 'package:flutter/material.dart';

import 'package:archonex/core/constants/app_strings.dart';
import 'package:archonex/core/widgets/category_placeholder_view.dart';

class NewsAppsView extends StatelessWidget {
  const NewsAppsView({super.key});

  @override
  Widget build(BuildContext context) {
    return const CategoryPlaceholderView(title: AppStrings.newsApps);
  }
}
