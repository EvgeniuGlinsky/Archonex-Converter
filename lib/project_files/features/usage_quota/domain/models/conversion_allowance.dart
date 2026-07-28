import 'dart:math' as math;

import 'package:equatable/equatable.dart';

import 'package:archonex_converter/core/constants/app_quota_limits.dart';

/// What a converter screen is allowed to do right now.
///
/// The one thing the converters read. Whether the room comes from an unspent
/// monthly count or from a subscription is settled before this is built, so no
/// screen has to ask about subscriptions to know if it can run.
final class ConversionAllowance extends Equatable {
  const ConversionAllowance({
    required this.usedFiles,
    required this.limit,
    required this.resetsAt,
  });

  /// An active subscription, or any platform the quota does not apply to.
  const ConversionAllowance.unlimited()
      : usedFiles = 0,
        limit = AppQuotaLimits.unlimited,
        resetsAt = null;

  final int usedFiles;

  /// Files per period, or [AppQuotaLimits.unlimited].
  final int limit;

  /// When the count refills, `null` when there is nothing to refill.
  final DateTime? resetsAt;

  bool get isUnlimited => limit == AppQuotaLimits.unlimited;

  /// Files still available this period. Never negative: a count can overshoot
  /// its limit if the limit is ever lowered, and a negative remainder would
  /// read as a bug everywhere it is displayed.
  int get remaining =>
      isUnlimited ? AppQuotaLimits.unlimited : math.max(0, limit - usedFiles);

  bool get isExhausted => !isUnlimited && remaining == 0;

  /// Whether a run of [fileCount] source files fits in what is left.
  bool allows(int fileCount) => isUnlimited || fileCount <= remaining;

  @override
  List<Object?> get props => <Object?>[usedFiles, limit, resetsAt];
}
