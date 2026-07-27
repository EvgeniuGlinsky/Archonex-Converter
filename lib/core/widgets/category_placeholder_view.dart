import 'package:flutter/material.dart';

import 'package:archonex/core/constants/app_spacing.dart';

/// Temporary landing screen for a product category.
///
/// Replace the usages one by one as the real category screens are built.
class CategoryPlaceholderView extends StatelessWidget {
  const CategoryPlaceholderView({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Center(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ),
    );
  }
}
