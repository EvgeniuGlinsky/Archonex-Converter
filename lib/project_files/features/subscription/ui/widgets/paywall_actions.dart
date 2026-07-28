import 'package:flutter/material.dart';

import 'package:archonex_converter/core/constants/app_spacing.dart';
import 'package:archonex_converter/core/widgets/app_primary_button.dart';
import 'package:archonex_converter/l10n/app_localizations.dart';
import 'package:archonex_converter/project_files/features/subscription/ui/bloc/paywall_bloc.dart';
import 'package:archonex_converter/project_files/features/subscription/ui/widgets/paywall_callbacks.dart';

/// The actions under the offer, and the restore link the App Store requires
/// beside them.
///
/// Both a purchase and an activation can be on screen at once, because on the
/// licence channel they are two halves of one flow: buy in a browser, come back
/// and paste the key. Buying leads, since that is what someone who has not paid
/// is here to do — activating is the quieter button for the smaller group who
/// already has a key.
///
/// With nothing on sale, activating is the only thing left and takes the primary
/// slot rather than sitting under a button that cannot do anything.
class PaywallActions extends StatelessWidget {
  const PaywallActions({
    required this.state,
    required this.callbacks,
    super.key,
  });

  final PaywallState state;
  final PaywallCallbacks callbacks;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final bool buys = state.showsPlans;
    final bool redeems = state.showsLicenseKeyField;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (buys)
          AppPrimaryButton(
            label: l10n.paywallSubscribeLabel,
            onPressed: state.canSubscribe ? callbacks.onSubscribePressed : null,
          ),
        if (redeems) ...<Widget>[
          if (buys) const SizedBox(height: AppSpacing.sm),
          _redeemButton(l10n, isPrimary: !buys),
        ],
        if (state.showsRestore) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: state.isReady ? callbacks.onRestorePressed : null,
            child: Text(l10n.paywallRestoreLabel),
          ),
        ],
      ],
    );
  }

  Widget _redeemButton(AppLocalizations l10n, {required bool isPrimary}) {
    final VoidCallback? onPressed =
        state.canRedeem ? callbacks.onRedeemPressed : null;

    if (isPrimary) {
      return AppPrimaryButton(
        label: l10n.paywallRedeemLabel,
        onPressed: onPressed,
      );
    }

    return OutlinedButton(
      onPressed: onPressed,
      child: Text(l10n.paywallRedeemLabel),
    );
  }
}
