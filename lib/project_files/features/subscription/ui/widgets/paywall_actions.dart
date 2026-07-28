import 'package:flutter/material.dart';

import 'package:archonex_converter/core/constants/app_spacing.dart';
import 'package:archonex_converter/core/widgets/app_primary_button.dart';
import 'package:archonex_converter/l10n/app_localizations.dart';
import 'package:archonex_converter/project_files/features/subscription/ui/bloc/paywall_bloc.dart';
import 'package:archonex_converter/project_files/features/subscription/ui/widgets/paywall_callbacks.dart';

/// The primary action, and the restore link the App Store requires beside it.
///
/// Which button this is depends on the channel: a store subscribes, a desktop
/// build activates a key. Restoring is only offered where a store holds the
/// receipt — there is nothing to restore from a key that was never entered.
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
    final bool redeems = state.showsLicenseKeyField;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppPrimaryButton(
          label: redeems ? l10n.paywallRedeemLabel : l10n.paywallSubscribeLabel,
          onPressed: _primaryAction(redeems),
        ),
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

  VoidCallback? _primaryAction(bool redeems) {
    if (redeems) {
      return state.canRedeem ? callbacks.onRedeemPressed : null;
    }

    return state.canSubscribe ? callbacks.onSubscribePressed : null;
  }
}
