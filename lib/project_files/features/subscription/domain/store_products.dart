import 'package:archonex_converter/project_files/features/subscription/domain/models/subscription_plan.dart';

/// The subscription products as the store knows them.
///
/// These strings are a contract with Google Play Console and nothing else. They
/// must match the subscription IDs created there **exactly**: a single character
/// out and `queryProducts` returns an empty list, the paywall says there is
/// nothing on sale, and the mistake looks like a billing outage rather than a
/// typo.
///
/// Two separate subscriptions rather than one with two base plans, because that
/// maps one-to-one onto [SubscriptionPlan] and keeps the choice of period out of
/// the store's offer machinery.
class StoreProducts {
  const StoreProducts._();

  static const String monthly = 'archonex_pro_monthly';
  static const String yearly = 'archonex_pro_yearly';

  static const Set<String> subscriptionIds = <String>{monthly, yearly};

  static bool isSubscription(String id) => subscriptionIds.contains(id);

  /// How often [id] renews, or `null` for a product this build does not sell.
  ///
  /// Nullable rather than throwing: the store can hand back a product that was
  /// added to the console but not to this build, and an unrecognised one should
  /// be ignored rather than crash the paywall.
  static SubscriptionPeriod? periodOf(String id) => switch (id) {
        monthly => SubscriptionPeriod.monthly,
        yearly => SubscriptionPeriod.yearly,
        _ => null,
      };
}
