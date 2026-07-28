import 'package:equatable/equatable.dart';

import 'package:archonex_converter/project_files/features/usage_quota/domain/models/quota_period.dart';

/// How many source files were converted in one period.
///
/// Source files, not produced ones: a batch of five photos is five, and one
/// PDF exploded into twelve pages is one. What was handed over is what the
/// user can predict in advance.
final class QuotaUsage extends Equatable {
  const QuotaUsage({required this.usedFiles, required this.period});

  QuotaUsage.emptyAt(DateTime date)
      : usedFiles = 0,
        period = QuotaPeriod.of(date);

  final int usedFiles;
  final QuotaPeriod period;

  QuotaUsage plus(int fileCount) =>
      QuotaUsage(usedFiles: usedFiles + fileCount, period: period);

  @override
  List<Object?> get props => <Object?>[usedFiles, period];
}
