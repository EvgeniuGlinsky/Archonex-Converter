import 'package:flutter/material.dart';

import 'package:archonex_converter/core/constants/app_spacing.dart';

/// Centres the splash content. Positioning only.
class SplashLayout extends StatelessWidget {
  const SplashLayout({required this.body, super.key});

  final Widget body;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Center(child: body),
      ),
    );
  }
}
