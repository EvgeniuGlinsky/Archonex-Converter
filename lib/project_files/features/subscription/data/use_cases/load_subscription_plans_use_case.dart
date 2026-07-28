import 'package:archonex_converter/project_files/features/subscription/domain/models/subscription_plan.dart';
import 'package:archonex_converter/project_files/features/subscription/domain/subscription_repo.dart';

/// Plans on offer, priced by whichever store answered.
class LoadSubscriptionPlansUseCase {
  const LoadSubscriptionPlansUseCase(this._repo);

  final SubscriptionRepo _repo;

  Future<List<SubscriptionPlan>> call() => _repo.loadPlans();
}
