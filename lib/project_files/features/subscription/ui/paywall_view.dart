import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:archonex_converter/core/constants/app_quota_limits.dart';
import 'package:archonex_converter/core/widgets/app_screen_header.dart';
import 'package:archonex_converter/core/widgets/app_screen_layout.dart';
import 'package:archonex_converter/l10n/app_localizations.dart';
import 'package:archonex_converter/project_files/features/subscription/domain/models/purchase_outcome.dart';
import 'package:archonex_converter/project_files/features/subscription/ui/bloc/paywall_bloc.dart';
import 'package:archonex_converter/project_files/features/subscription/ui/mappers/purchase_outcome_ui.dart';
import 'package:archonex_converter/project_files/features/subscription/ui/widgets/paywall_actions.dart';
import 'package:archonex_converter/project_files/features/subscription/ui/widgets/paywall_body.dart';
import 'package:archonex_converter/project_files/features/subscription/ui/widgets/paywall_callbacks.dart';

/// The subscription screen.
///
/// Every attempt is announced exactly once, through the listener below —
/// including cancellation, so a store sheet dismissed by accident does not
/// leave the screen looking like it ignored the tap.
class PaywallView extends StatelessWidget {
  const PaywallView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<PaywallBloc, PaywallState>(
      listenWhen: (previous, current) =>
          previous.outcome != current.outcome && current.outcome != null,
      listener: _onOutcome,
      child: Scaffold(
        appBar: AppBar(),
        body: BlocBuilder<PaywallBloc, PaywallState>(
          builder: (context, state) => AppScreenLayout(
            header: AppScreenHeader(
              title: AppLocalizations.of(context)!.paywallTitle,
              // The metered number, not this platform's. The screen describes
              // what a subscription is for; on a platform that never counts, the
              // platform-aware getter would render the sentinel.
              subtitle: AppLocalizations.of(context)!
                  .paywallSubtitle(AppQuotaLimits.meteredFilesPerMonth),
            ),
            body: PaywallBody(state: state, callbacks: _callbacks(context)),
            // Nothing left to buy once the device is entitled.
            bottom: state.isSubscribed
                ? null
                : PaywallActions(
                    state: state,
                    callbacks: _callbacks(context),
                  ),
          ),
        ),
      ),
    );
  }

  PaywallCallbacks _callbacks(BuildContext context) {
    return PaywallCallbacks(
      onPlanSelected: (id) => _add(context, PaywallPlanSelected(id)),
      onLicenseKeyChanged: (key) => _add(context, PaywallLicenseKeyChanged(key)),
      onRedeemPressed: () =>
          _add(context, const PaywallLicenseKeyRedeemRequested()),
      onSubscribePressed: () =>
          _add(context, const PaywallSubscribeRequested()),
      onRestorePressed: () => _add(context, const PaywallRestoreRequested()),
      onRetryPlansPressed: () => _add(context, const PaywallPlansRetried()),
    );
  }

  void _add(BuildContext context, PaywallEvent event) {
    context.read<PaywallBloc>().add(event);
  }

  void _onOutcome(BuildContext context, PaywallState state) {
    final PurchaseOutcome? outcome = state.outcome;
    if (outcome == null) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(outcome.message(context))),
    );
  }
}
