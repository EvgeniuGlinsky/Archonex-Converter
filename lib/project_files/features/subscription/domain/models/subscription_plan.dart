import 'package:equatable/equatable.dart';

/// How often a plan renews, or that it does not.
enum SubscriptionPeriod {
  monthly,
  yearly,

  /// Bought once, kept for good.
  ///
  /// For the platforms where a subscription is not worth the machinery it needs.
  /// A store handles renewals, dunning and cancellation for free; anywhere else
  /// all three would have to be built and run, and a one-time unlock has none of
  /// them — nothing expires, so nothing has to be checked again.
  lifetime,
}

/// One purchasable plan, as the store describes it.
///
/// [priceLabel] arrives from the store already formatted for the user's
/// country and currency. It is never composed in the app: a hand-built price
/// string is how an app ends up advertising a number the checkout does not
/// charge.
final class SubscriptionPlan extends Equatable {
  const SubscriptionPlan({
    required this.id,
    required this.period,
    required this.priceLabel,
  });

  /// Product identifier in whichever store this plan came from.
  final String id;

  final SubscriptionPeriod period;

  final String priceLabel;

  @override
  List<Object?> get props => <Object?>[id, period, priceLabel];
}
