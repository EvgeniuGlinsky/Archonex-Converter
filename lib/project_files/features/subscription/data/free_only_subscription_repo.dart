import 'package:flutter/foundation.dart';

import 'package:archonex_converter/project_files/features/subscription/domain/models/plan_catalog.dart';
import 'package:archonex_converter/project_files/features/subscription/domain/models/purchase_channel.dart';
import 'package:archonex_converter/project_files/features/subscription/domain/models/purchase_outcome.dart';
import 'package:archonex_converter/project_files/features/subscription/domain/models/subscription_plan.dart';
import 'package:archonex_converter/project_files/features/subscription/domain/models/subscription_status.dart';
import 'package:archonex_converter/project_files/features/subscription/domain/subscription_repo.dart';

/// The implementation shipping today: the paid tier is designed but not yet
/// connected to any store, so no device is entitled and nothing can be bought.
///
/// [channel] still reports what this platform *will* use, rather than
/// [PurchaseChannel.unavailable] everywhere. That keeps the paywall honest in
/// both of its forms — store sheet on mobile, licence key on desktop — and
/// makes the whole screen testable before a single billing account exists.
///
/// Replacing this means adding a sibling in `data/` and returning it from the
/// platform boundary. Nothing above this layer changes.
class FreeOnlySubscriptionRepo implements SubscriptionRepo {
  FreeOnlySubscriptionRepo({required this.channel});

  @override
  final PurchaseChannel channel;

  final ValueNotifier<SubscriptionStatus> _status =
      ValueNotifier<SubscriptionStatus>(const SubscriptionStatus.free());

  @override
  ValueListenable<SubscriptionStatus> get statusListenable => _status;

  @override
  Future<void> refresh() async {}

  /// No store to price them, and a price written in the app would be a price
  /// the checkout does not honour.
  ///
  /// Reported as [CatalogProblem.nothingOnSale] rather than
  /// [CatalogProblem.storeUnreachable]: nothing here failed, and offering a
  /// retry button for a shop that will never open would be a lie. The paywall
  /// prefers its own channel notice over this one anyway — see
  /// `PaywallState.showsStoreBuildNotice`.
  @override
  Future<PlanCatalog> loadPlans() async =>
      const PlanCatalog.unavailable(CatalogProblem.nothingOnSale);

  @override
  Future<PurchaseOutcome> purchase(SubscriptionPlan plan) async =>
      PurchaseOutcome.unavailable;

  @override
  Future<PurchaseOutcome> redeemLicenseKey(String key) async =>
      PurchaseOutcome.unavailable;

  @override
  Future<PurchaseOutcome> restore() async => PurchaseOutcome.unavailable;
}
