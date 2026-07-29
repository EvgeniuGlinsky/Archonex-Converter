import 'package:archonex_converter/project_files/features/subscription/domain/models/plan_catalog.dart';
import 'package:archonex_converter/project_files/features/subscription/domain/subscription_repo.dart';

/// Plans on offer, priced by whichever store answered — or why there are none.
class LoadSubscriptionPlansUseCase {
  const LoadSubscriptionPlansUseCase(this._repo);

  final SubscriptionRepo _repo;

  Future<PlanCatalog> call() => _repo.loadPlans();
}
