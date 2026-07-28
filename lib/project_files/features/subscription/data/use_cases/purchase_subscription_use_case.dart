import 'package:archonex_converter/project_files/features/subscription/domain/models/purchase_outcome.dart';
import 'package:archonex_converter/project_files/features/subscription/domain/models/subscription_plan.dart';
import 'package:archonex_converter/project_files/features/subscription/domain/subscription_repo.dart';

/// Buys [plan] through the platform's store sheet.
class PurchaseSubscriptionUseCase {
  const PurchaseSubscriptionUseCase(this._repo);

  final SubscriptionRepo _repo;

  Future<PurchaseOutcome> call(SubscriptionPlan plan) => _repo.purchase(plan);
}
