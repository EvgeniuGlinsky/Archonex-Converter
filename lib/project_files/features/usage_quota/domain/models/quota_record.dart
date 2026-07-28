import 'package:equatable/equatable.dart';

import 'package:archonex_converter/project_files/features/usage_quota/domain/models/quota_usage.dart';

/// Everything the counter has to survive a restart with.
///
/// [lastSeen] is not decoration: a device clock can be moved, and the only
/// defence an offline app has is refusing to believe a clock that went
/// backwards. See `UsageQuotaRepoImpl` for what is and is not defended against.
final class QuotaRecord extends Equatable {
  const QuotaRecord({required this.usage, required this.lastSeen});

  final QuotaUsage usage;

  /// The latest moment this device was known to be at.
  final DateTime lastSeen;

  @override
  List<Object?> get props => <Object?>[usage, lastSeen];
}
