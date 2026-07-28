import 'package:archonex_converter/project_files/features/subscription/domain/subscription_repo.dart';

/// Re-reads the entitlement on launch, alongside the quota.
class RefreshSubscriptionUseCase {
  const RefreshSubscriptionUseCase(this._repo);

  final SubscriptionRepo _repo;

  Future<void> call() => _repo.refresh();
}
