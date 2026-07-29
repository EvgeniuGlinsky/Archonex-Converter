import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:archonex_converter/project_files/features/subscription/data/use_cases/get_purchase_channel_use_case.dart';
import 'package:archonex_converter/project_files/features/subscription/data/use_cases/load_subscription_plans_use_case.dart';
import 'package:archonex_converter/project_files/features/subscription/data/use_cases/purchase_subscription_use_case.dart';
import 'package:archonex_converter/project_files/features/subscription/data/use_cases/redeem_license_key_use_case.dart';
import 'package:archonex_converter/project_files/features/subscription/data/use_cases/restore_purchases_use_case.dart';
import 'package:archonex_converter/project_files/features/subscription/data/use_cases/watch_subscription_status_use_case.dart';
import 'package:archonex_converter/project_files/features/subscription/domain/models/plan_catalog.dart';
import 'package:archonex_converter/project_files/features/subscription/domain/models/purchase_channel.dart';
import 'package:archonex_converter/project_files/features/subscription/domain/models/purchase_outcome.dart';
import 'package:archonex_converter/project_files/features/subscription/domain/models/subscription_plan.dart';
import 'package:archonex_converter/project_files/features/subscription/domain/models/subscription_status.dart';

part 'paywall_event.dart';
part 'paywall_state.dart';

/// Drives the subscription screen for both payment routes.
///
/// The entitlement is never set from the outcome of a purchase: it arrives
/// through the status stream, which is the same source a restore, a refund or
/// a purchase made on another screen would come through. An outcome only says
/// how the attempt went, so the screen can announce it once.
class PaywallBloc extends Bloc<PaywallEvent, PaywallState> {
  PaywallBloc({
    required GetPurchaseChannelUseCase getPurchaseChannel,
    required WatchSubscriptionStatusUseCase watchSubscriptionStatus,
    required LoadSubscriptionPlansUseCase loadPlans,
    required PurchaseSubscriptionUseCase purchase,
    required RedeemLicenseKeyUseCase redeemLicenseKey,
    required RestorePurchasesUseCase restorePurchases,
  })  : _getPurchaseChannel = getPurchaseChannel,
        _watchSubscriptionStatus = watchSubscriptionStatus,
        _loadPlans = loadPlans,
        _purchase = purchase,
        _redeemLicenseKey = redeemLicenseKey,
        _restorePurchases = restorePurchases,
        super(const PaywallState()) {
    on<PaywallStarted>(_onStarted, transformer: restartable());
    on<PaywallPlanSelected>(_onPlanSelected, transformer: sequential());
    on<PaywallLicenseKeyChanged>(_onLicenseKeyChanged, transformer: sequential());
    // droppable: the store shows one sheet, so extra taps must not queue up a
    // second purchase behind the first.
    on<PaywallSubscribeRequested>(_onSubscribe, transformer: droppable());
    on<PaywallLicenseKeyRedeemRequested>(_onRedeem, transformer: droppable());
    on<PaywallRestoreRequested>(_onRestore, transformer: droppable());
    on<PaywallPlansRetried>(_onRetryPlans, transformer: droppable());
  }

  final GetPurchaseChannelUseCase _getPurchaseChannel;
  final WatchSubscriptionStatusUseCase _watchSubscriptionStatus;
  final LoadSubscriptionPlansUseCase _loadPlans;
  final PurchaseSubscriptionUseCase _purchase;
  final RedeemLicenseKeyUseCase _redeemLicenseKey;
  final RestorePurchasesUseCase _restorePurchases;

  Future<void> _onStarted(
    PaywallStarted event,
    Emitter<PaywallState> emit,
  ) async {
    final PlanCatalog catalog = await _loadPlans();

    emit(_withCatalog(catalog).copyWith(channel: _getPurchaseChannel()));

    await emit.onEach<SubscriptionStatus>(
      _watchSubscriptionStatus(),
      onData: (status) => emit(state.copyWith(isSubscribed: status.isActive)),
    );
  }

  /// A second ask, for a store that would not answer the first time.
  ///
  /// Its own handler rather than re-adding [PaywallStarted]: that one is
  /// `restartable()` and never returns — it holds the `emit.onEach` watching the
  /// entitlement for as long as the screen lives, so restarting it would drop the
  /// subscription arriving from another device mid-retry.
  Future<void> _onRetryPlans(
    PaywallPlansRetried event,
    Emitter<PaywallState> emit,
  ) async {
    if (!state.canRetryPlans) {
      return;
    }

    emit(state.copyWith(status: PaywallStatus.loading, clearOutcome: true));

    emit(_withCatalog(await _loadPlans()));
  }

  /// The half [_onStarted] and [_onRetryPlans] share: whatever the store said,
  /// written into the state as one consistent picture.
  PaywallState _withCatalog(PlanCatalog catalog) {
    final String? planId = _defaultPlanId(catalog.plans);

    return state.copyWith(
      status: PaywallStatus.ready,
      plans: catalog.plans,
      catalogProblem: catalog.problem,
      clearCatalogProblem: catalog.problem == null,
      selectedPlanId: planId,
      clearSelectedPlan: planId == null,
    );
  }

  /// The yearly plan when there is one: it is the cheaper way to pay, and
  /// preselecting the pricier option would be a dark pattern.
  String? _defaultPlanId(List<SubscriptionPlan> plans) {
    if (plans.isEmpty) {
      return null;
    }

    for (final SubscriptionPlan plan in plans) {
      if (plan.period == SubscriptionPeriod.yearly) {
        return plan.id;
      }
    }

    return plans.first.id;
  }

  void _onPlanSelected(
    PaywallPlanSelected event,
    Emitter<PaywallState> emit,
  ) {
    if (state.isWorking) {
      return;
    }

    emit(state.copyWith(selectedPlanId: event.planId, clearOutcome: true));
  }

  void _onLicenseKeyChanged(
    PaywallLicenseKeyChanged event,
    Emitter<PaywallState> emit,
  ) {
    emit(state.copyWith(licenseKey: event.key, clearOutcome: true));
  }

  Future<void> _onSubscribe(
    PaywallSubscribeRequested event,
    Emitter<PaywallState> emit,
  ) async {
    final SubscriptionPlan? plan = state.selectedPlan;
    if (!state.canSubscribe || plan == null) {
      return;
    }

    await _attempt(emit, () => _purchase(plan));
  }

  Future<void> _onRedeem(
    PaywallLicenseKeyRedeemRequested event,
    Emitter<PaywallState> emit,
  ) async {
    if (!state.canRedeem) {
      return;
    }

    await _attempt(emit, () => _redeemLicenseKey(state.licenseKey));
  }

  Future<void> _onRestore(
    PaywallRestoreRequested event,
    Emitter<PaywallState> emit,
  ) async {
    if (!state.isReady) {
      return;
    }

    await _attempt(emit, _restorePurchases.call);
  }

  /// The shared half of all three: park the screen, run [action], and report
  /// how it went.
  Future<void> _attempt(
    Emitter<PaywallState> emit,
    Future<PurchaseOutcome> Function() action,
  ) async {
    emit(state.copyWith(status: PaywallStatus.working, clearOutcome: true));

    final PurchaseOutcome outcome = await action();

    emit(state.copyWith(status: PaywallStatus.ready, outcome: outcome));
  }
}
