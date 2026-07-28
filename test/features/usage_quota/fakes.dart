import 'package:flutter/foundation.dart';

import 'package:archonex_converter/project_files/features/usage_quota/domain/models/quota_record.dart';
import 'package:archonex_converter/project_files/features/usage_quota/domain/models/quota_usage.dart';
import 'package:archonex_converter/project_files/features/usage_quota/domain/quota_storage.dart';
import 'package:archonex_converter/project_files/features/usage_quota/domain/usage_quota_repo.dart';

/// Storage that lives in the test rather than on the device.
class FakeQuotaStorage implements QuotaStorage {
  FakeQuotaStorage([this.record]);

  QuotaRecord? record;
  int writeCount = 0;

  @override
  Future<QuotaRecord?> read() async => record;

  @override
  Future<void> write(QuotaRecord record) async {
    this.record = record;
    writeCount++;
  }
}

/// Storage that refuses to answer, for the paths that must survive it.
class BrokenQuotaStorage implements QuotaStorage {
  @override
  Future<QuotaRecord?> read() async => throw Exception('unreadable');

  @override
  Future<void> write(QuotaRecord record) async => throw Exception('unwritable');
}

/// Counter driven entirely by the test.
///
/// Used where a test is about a *converter* rather than about the counter
/// itself, so the rules around months and clocks stay in one place —
/// `UsageQuotaRepoImpl` and its own test.
class FakeUsageQuotaRepo implements UsageQuotaRepo {
  FakeUsageQuotaRepo({int usedFiles = 0, DateTime? now})
      : _usage = ValueNotifier<QuotaUsage>(
          QuotaUsage.emptyAt(now ?? DateTime(2026, 7, 27)).plus(usedFiles),
        );

  final ValueNotifier<QuotaUsage> _usage;

  int refreshCallCount = 0;

  /// Every amount [consume] was asked for, in order.
  final List<int> consumed = <int>[];

  @override
  ValueListenable<QuotaUsage> get usageListenable => _usage;

  @override
  Future<void> refresh() async => refreshCallCount++;

  @override
  Future<void> consume(int fileCount) async {
    consumed.add(fileCount);
    _usage.value = _usage.value.plus(fileCount);
  }

  /// Moves the count without going through [consume], for setting a test up.
  void setUsed(int usedFiles) => _usage.value = QuotaUsage(
        usedFiles: usedFiles,
        period: _usage.value.period,
      );
}
