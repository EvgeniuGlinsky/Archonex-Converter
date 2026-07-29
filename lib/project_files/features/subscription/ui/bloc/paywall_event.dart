part of 'paywall_bloc.dart';

sealed class PaywallEvent extends Equatable {
  const PaywallEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

final class PaywallStarted extends PaywallEvent {
  const PaywallStarted();
}

final class PaywallPlanSelected extends PaywallEvent {
  const PaywallPlanSelected(this.planId);

  final String planId;

  @override
  List<Object?> get props => <Object?>[planId];
}

final class PaywallSubscribeRequested extends PaywallEvent {
  const PaywallSubscribeRequested();
}

final class PaywallLicenseKeyChanged extends PaywallEvent {
  const PaywallLicenseKeyChanged(this.key);

  final String key;

  @override
  List<Object?> get props => <Object?>[key];
}

final class PaywallLicenseKeyRedeemRequested extends PaywallEvent {
  const PaywallLicenseKeyRedeemRequested();
}

final class PaywallRestoreRequested extends PaywallEvent {
  const PaywallRestoreRequested();
}

/// Ask the store what it sells again, without leaving the screen.
final class PaywallPlansRetried extends PaywallEvent {
  const PaywallPlansRetried();
}
