import 'package:equatable/equatable.dart';

import 'package:archonex_converter/project_files/features/subscription/domain/models/subscription_plan.dart';

/// Why there is nothing to show on the paywall.
///
/// Two answers rather than one, because they call for opposite things from the
/// user: a store that would not answer is worth trying again in a moment, and a
/// store that answered with an empty shelf is not.
enum CatalogProblem {
  /// The store could not be reached, or refused to talk to this build. The
  /// device may simply be offline.
  storeUnreachable,

  /// The store answered, and sells none of the products this app asks for. In a
  /// Play build that means the subscriptions are missing from the console, not
  /// yet activated, or unpriced in this account's country.
  nothingOnSale,
}

/// What is on sale, or why nothing is.
///
/// **Why not just a list.** An empty `List<SubscriptionPlan>` was the previous
/// answer to all three of "the phone is offline", "the store refused" and "the
/// console has no products in it". The paywall could only print one sentence for
/// all three, which is how a shop that was never opened looked exactly like a
/// dropped connection — and neither the user nor the developer could tell which
/// they were looking at. The problem is carried instead of thrown because none of
/// this is exceptional: a store with nothing on it is a normal state of the
/// world, and `StoreSubscriptionRepo` still invents no prices of its own.
final class PlanCatalog extends Equatable {
  /// The store answered with something to sell.
  const PlanCatalog.offered(this.plans) : problem = null;

  /// Nothing to sell, and [problem] says which kind of nothing.
  const PlanCatalog.unavailable(CatalogProblem this.problem)
      : plans = const <SubscriptionPlan>[];

  /// Plans to display, priced by the store. Empty whenever [problem] is set.
  final List<SubscriptionPlan> plans;

  /// `null` exactly when [plans] is non-empty.
  final CatalogProblem? problem;

  @override
  List<Object?> get props => <Object?>[plans, problem];
}
