part of 'paywall_bloc.dart';

enum PaywallStatus {
  /// Asking the store what it sells.
  loading,
  ready,

  /// A purchase, redemption or restore is in flight.
  working,
}

final class PaywallState extends Equatable {
  const PaywallState({
    this.status = PaywallStatus.loading,
    this.channel = PurchaseChannel.unavailable,
    this.plans = const <SubscriptionPlan>[],
    this.selectedPlanId,
    this.isSubscribed = false,
    this.licenseKey = '',
    this.outcome,
  });

  final PaywallStatus status;

  /// Which paywall this is: a store sheet, or a key from the website.
  final PurchaseChannel channel;

  /// What the store offers, priced by the store. Empty while nothing is on
  /// sale yet, which the screen says rather than papering over.
  final List<SubscriptionPlan> plans;

  final String? selectedPlanId;

  final bool isSubscribed;

  /// What has been typed into the licence key field so far.
  final String licenseKey;

  /// How the last attempt ended, `null` when none was made or it has already
  /// been announced.
  final PurchaseOutcome? outcome;

  SubscriptionPlan? get selectedPlan {
    final String? id = selectedPlanId;

    if (id == null) {
      return null;
    }

    for (final SubscriptionPlan plan in plans) {
      if (plan.id == id) {
        return plan;
      }
    }

    return null;
  }

  bool get isWorking => status == PaywallStatus.working;

  bool get isReady => status == PaywallStatus.ready;

  bool get showsPlans => channel == PurchaseChannel.store;

  bool get showsLicenseKeyField => channel == PurchaseChannel.licenseKey;

  /// Restoring only makes sense where a store keeps the receipt.
  bool get showsRestore => channel == PurchaseChannel.store;

  bool get canSubscribe =>
      isReady && !isSubscribed && selectedPlan != null;

  bool get canRedeem =>
      isReady && !isSubscribed && licenseKey.trim().isNotEmpty;

  PaywallState copyWith({
    PaywallStatus? status,
    PurchaseChannel? channel,
    List<SubscriptionPlan>? plans,
    String? selectedPlanId,
    bool? isSubscribed,
    String? licenseKey,
    PurchaseOutcome? outcome,
    bool clearOutcome = false,
  }) {
    return PaywallState(
      status: status ?? this.status,
      channel: channel ?? this.channel,
      plans: plans ?? this.plans,
      selectedPlanId: selectedPlanId ?? this.selectedPlanId,
      isSubscribed: isSubscribed ?? this.isSubscribed,
      licenseKey: licenseKey ?? this.licenseKey,
      outcome: clearOutcome ? null : outcome ?? this.outcome,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        status,
        channel,
        plans,
        selectedPlanId,
        isSubscribed,
        licenseKey,
        outcome,
      ];
}
