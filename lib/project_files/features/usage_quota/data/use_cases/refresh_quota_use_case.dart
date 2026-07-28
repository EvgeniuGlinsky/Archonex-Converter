import 'package:archonex_converter/project_files/features/usage_quota/domain/usage_quota_repo.dart';

/// Brings the counter in from storage, rolling the period over if it is due.
///
/// Run once on the splash screen, where the wait is already being spent.
class RefreshQuotaUseCase {
  const RefreshQuotaUseCase(this._repo);

  final UsageQuotaRepo _repo;

  Future<void> call() => _repo.refresh();
}
