import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:archonex_converter/project_files/features/subscription/data/use_cases/get_purchase_channel_use_case.dart';
import 'package:archonex_converter/project_files/features/subscription/data/use_cases/load_subscription_plans_use_case.dart';
import 'package:archonex_converter/project_files/features/subscription/data/use_cases/purchase_subscription_use_case.dart';
import 'package:archonex_converter/project_files/features/subscription/data/use_cases/redeem_license_key_use_case.dart';
import 'package:archonex_converter/project_files/features/subscription/data/use_cases/restore_purchases_use_case.dart';
import 'package:archonex_converter/project_files/features/subscription/data/use_cases/watch_subscription_status_use_case.dart';
import 'package:archonex_converter/project_files/features/subscription/domain/subscription_repo.dart';
import 'package:archonex_converter/project_files/features/subscription/ui/bloc/paywall_bloc.dart';
import 'package:archonex_converter/project_files/features/subscription/ui/paywall_view.dart';

/// Wires the paywall dependencies. No UI lives here.
///
/// The repository is the app-wide one, not a fresh instance: an entitlement
/// bought here has to be visible to the three converter screens immediately.
class PaywallPage extends StatelessWidget {
  const PaywallPage({super.key});

  @override
  Widget build(BuildContext context) {
    final SubscriptionRepo repo = context.read<SubscriptionRepo>();

    return BlocProvider<PaywallBloc>(
      create: (_) => PaywallBloc(
        getPurchaseChannel: GetPurchaseChannelUseCase(repo),
        watchSubscriptionStatus: WatchSubscriptionStatusUseCase(repo),
        loadPlans: LoadSubscriptionPlansUseCase(repo),
        purchase: PurchaseSubscriptionUseCase(repo),
        redeemLicenseKey: RedeemLicenseKeyUseCase(repo),
        restorePurchases: RestorePurchasesUseCase(repo),
      )..add(const PaywallStarted()),
      child: const PaywallView(),
    );
  }
}
