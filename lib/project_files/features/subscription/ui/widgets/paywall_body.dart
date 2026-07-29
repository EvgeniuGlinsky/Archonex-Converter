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
/// Two independent questions, not one choice of three: whether there is
/// anything on sale, and whether this build takes a licence key. On the licence
/// channel both are true, so the plans and the key field appear together — the
/// user buys in a browser and comes back to the same screen to paste what they
/// were sent.
///
/// When there is nothing on sale the screen says so plainly, and says which
/// nothing it is — a shop that is shut, or a store that would not answer. That
/// is not a placeholder to be tidied away later: offering a purchase that cannot
/// be taken is worse than admitting the shop is shut, and only one of those two
/// is worth asking again about. The key field stays either way, because a key
/// bought yesterday still has to be redeemable today.
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

    return <Widget>[
      if (state.showsPlans)
        ..._plans(context)
      else if (state.showsStoreBuildNotice)
        FileSizeLimitNotice(l10n.paywallStoreBuildOnlyNotice)
      else if (state.showsStoreUnreachableNotice) ...<Widget>[
        FileSizeLimitNotice(l10n.paywallStoreUnreachableNotice),
        const SizedBox(height: AppSpacing.sm),
        // Only here. A store that answered with an empty shelf says the same
        // thing however often it is asked, and a retry button under that notice
        // would only invite the user to prove it.
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton(
            onPressed:
                state.canRetryPlans ? callbacks.onRetryPlansPressed : null,
            child: Text(l10n.paywallRetryLabel),
          ),
        ),
      ] else
        FileSizeLimitNotice(l10n.paywallNoPlansNotice),
      if (state.showsLicenseKeyField) ...<Widget>[
        const SizedBox(height: _gap),
        FileSizeLimitNotice(l10n.paywallBuyOnWebNotice),
        const SizedBox(height: _gap),
        LicenseKeyField(
          value: state.licenseKey,
          isEnabled: !state.isWorking,
          onChanged: callbacks.onLicenseKeyChanged,
          onSubmitted: callbacks.onRedeemPressed,
        ),
      ],
    ];
  }

  List<Widget> _plans(BuildContext context) {
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
