import 'package:flutter/material.dart';

import 'package:archonex_converter/core/constants/app_spacing.dart';
import 'package:archonex_converter/l10n/app_localizations.dart';

/// What the subscription actually changes, in three lines.
///
/// Deliberately short on promises: the offline guarantee and the full size
/// ceilings are not perks of paying, they are how the app already works, and
/// the last line says so instead of implying otherwise.
class PaywallBenefits extends StatelessWidget {
  const PaywallBenefits({super.key});

  static const double _iconSize = 20;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _Benefit(icon: Icons.all_inclusive_rounded, text: l10n.paywallBenefitUnlimited),
        const SizedBox(height: AppSpacing.md),
        _Benefit(icon: Icons.widgets_outlined, text: l10n.paywallBenefitConverters),
        const SizedBox(height: AppSpacing.md),
        _Benefit(icon: Icons.wifi_off_rounded, text: l10n.paywallBenefitOffline),
      ],
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(
          icon,
          size: PaywallBenefits._iconSize,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: Text(text, style: theme.textTheme.bodyLarge)),
      ],
    );
  }
}
