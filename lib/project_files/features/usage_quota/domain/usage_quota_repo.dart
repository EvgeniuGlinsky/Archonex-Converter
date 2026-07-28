import 'package:flutter/foundation.dart';

import 'package:archonex_converter/project_files/features/usage_quota/domain/models/quota_usage.dart';

/// Contract for the monthly conversion counter.
abstract interface class UsageQuotaRepo {
  /// The current count, already rolled over if the month has turned.
  ///
  /// A listenable rather than a getter because three converter screens read
  /// the same number and any of them can change it — see `LanguageRepo` for
  /// the same shape used for the same reason.
  ValueListenable<QuotaUsage> get usageListenable;

  /// Re-reads storage and rolls the period over if it is due.
  ///
  /// Called on launch and whenever a screen starts watching, because an app
  /// left open across midnight on the 1st would otherwise keep showing last
  /// month's count.
  Future<void> refresh();

  /// Adds [fileCount] source files to the current period.
  ///
  /// Whether the run should be counted at all is decided above this, in
  /// `ConsumeQuotaUseCase` — a subscriber's conversions never reach here.
  Future<void> consume(int fileCount);
}
