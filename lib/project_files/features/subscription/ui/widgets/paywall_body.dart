import 'package:flutter/material.dart';

import 'package:archonex_converter/core/constants/app_spacing.dart';
import 'package:archonex_converter/l10n/app_localizations.dart';
import 'package:archonex_converter/project_files/features/converter_shared/ui/widgets/file_size_limit_notice.dart';
import 'package:archonex_converter/project_files/features/subscription/domain/models/subscription_plan.dart';
import 'package:archonex_converter/project_files/features/subscription/ui/bloc/paywall_bloc.dart';
import 'package:archonex_converter/project_files/features/subscription/ui/mappers/subscription_period_ui.dart';
import 'package:archonex_converter/project_files/features/subscription/ui/widgets/license_key_field.dart';
import 'package:archonex_converter/project_files/features/subscription/ui/widgets/paywall_benefits.dart';
import 'package:archonex_converter/project_files/features/subscription/ui/widgets/paywall_callbacks.dart';
import 'package:archonex_converter/project_files/features/subscription/ui/widgets/plan_option_tile.dart';
import 'package:archonex_converter/project_files/features/subscription/ui/widgets/subscription_active_card.dart';

/// Everything between the header and the primary action.
///
/// Three shapes, one per [PaywallState.channel]: a list of store plans, a
/// licence key field, or — where neither exists yet — a plain statement that
/// there is nothing to buy. The last one is not a placeholder to be tidied
/// away later: a screen that offers a purchase it cannot take is worse than
/// one that admits the shop is closed.
class PaywallBody extends StatelessWidget {
  const PaywallBody({
    required this.state,
    required this.callbacks,
    super.key,
  });

  static const double _gap = AppSpacing.lg;

  final PaywallState state;
  final PaywallCallbacks callbacks;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: <Widget>[
        const PaywallBenefits(),
        const SizedBox(height: AppSpacing.xl),
        if (state.isSubscribed)
          const SubscriptionActiveCard()
        else
          ..._offer(context),
      ],
    );
  }

  List<Widget> _offer(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    if (state.showsLicenseKeyField) {
      return <Widget>[
        FileSizeLimitNotice(l10n.paywallBuyOnWebNotice),
        const SizedBox(height: _gap),
        LicenseKeyField(
          value: state.licenseKey,
          isEnabled: !state.isWorking,
          onChanged: callbacks.onLicenseKeyChanged,
          onSubmitted: callbacks.onRedeemPressed,
        ),
      ];
    }

    if (state.plans.isEmpty) {
      return <Widget>[FileSizeLimitNotice(l10n.paywallNoPlansNotice)];
    }

    return <Widget>[
      for (final SubscriptionPlan plan in state.plans) ...<Widget>[
        PlanOptionTile(
          label: plan.period.label(context),
          priceLabel: plan.priceLabel,
          isSelected: plan.id == state.selectedPlanId,
          isEnabled: !state.isWorking,
          onPressed: () => callbacks.onPlanSelected(plan.id),
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    ];
  }
}
