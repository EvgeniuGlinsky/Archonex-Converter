import 'package:equatable/equatable.dart';

import 'package:archonex_converter/project_files/features/subscription/domain/models/subscription_plan.dart';

/// One plan the licence service is currently selling, and where to buy it.
///
/// The pair travels together because the app must never compose either half:
/// the price is whatever the payment provider will actually charge, and the
/// checkout URL is whatever it will actually honour. Both are read from the
/// service, so a price change is a dashboard edit rather than a release — and
/// builds already downloaded from GitHub start selling the day the service has
/// something to sell.
final class CheckoutOffer extends Equatable {
  const CheckoutOffer({required this.plan, required this.checkoutUrl});

  final SubscriptionPlan plan;

  /// Opened in the user's browser. Checkout happens there and comes back as a
  /// licence key, which is the only shape that works for a build a store never
  /// installed.
  final Uri checkoutUrl;

  @override
  List<Object?> get props => <Object?>[plan, checkoutUrl];
}
