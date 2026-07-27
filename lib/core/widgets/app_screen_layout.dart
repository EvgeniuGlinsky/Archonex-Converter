import 'package:flutter/material.dart';

import 'package:archonex/core/constants/app_breakpoints.dart';
import 'package:archonex/core/constants/app_spacing.dart';

/// Positioning-only layout shared by the full-page flow screens.
///
/// It never builds content: every slot arrives through the constructor.
class AppScreenLayout extends StatelessWidget {
  const AppScreenLayout({
    required this.header,
    required this.body,
    this.bottom,
    super.key,
  });

  final Widget header;
  final Widget body;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppBreakpoints.maxContentWidth,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                header,
                const SizedBox(height: AppSpacing.xl),
                Expanded(child: body),
                if (bottom != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.xl),
                  bottom!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
