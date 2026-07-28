import 'package:flutter_test/flutter_test.dart';

import 'package:archonex_converter/project_files/features/usage_quota/data/usage_quota_repo_impl.dart';
import 'package:archonex_converter/project_files/features/usage_quota/domain/models/quota_period.dart';
import 'package:archonex_converter/project_files/features/usage_quota/domain/models/quota_record.dart';
import 'package:archonex_converter/project_files/features/usage_quota/domain/models/quota_usage.dart';

import 'fakes.dart';

void main() {
  late FakeQuotaStorage storage;
  late DateTime now;

  final DateTime july = DateTime(2026, 7, 27, 10);

  setUp(() {
    storage = FakeQuotaStorage();
    now = july;
  });

  UsageQuotaRepoImpl buildRepo() =>
      UsageQuotaRepoImpl(storage: storage, now: () => now);

  /// A record as it would have been left by an earlier run.
  QuotaRecord storedRecord({required int usedFiles, required DateTime at}) =>
      QuotaRecord(
        usage: QuotaUsage(usedFiles: usedFiles, period: QuotaPeriod.of(at)),
        lastSeen: at,
      );

  group('periods', () {
    test('a period survives the integer it is stored as', () {
      const QuotaPeriod december = QuotaPeriod(year: 2026, month: 12);
      const QuotaPeriod january = QuotaPeriod(year: 2027, month: 1);

      expect(QuotaPeriod.fromKey(december.key), december);
      expect(QuotaPeriod.fromKey(january.key), january);
      expect(december.key < january.key, isTrue);
    });

    test('a period refills at midnight on the 1st of the next month', () {
      expect(
        const QuotaPeriod(year: 2026, month: 7).resetsAt,
        DateTime(2026, 8),
      );
      expect(
        const QuotaPeriod(year: 2026, month: 12).resetsAt,
        DateTime(2027),
      );
    });
  });

  group('refresh', () {
    test('a first run starts from nothing and writes that down', () async {
      final UsageQuotaRepoImpl repo = buildRepo();

      await repo.refresh();

      expect(repo.usageListenable.value.usedFiles, 0);
      expect(repo.usageListenable.value.period, QuotaPeriod.of(july));
      expect(storage.writeCount, 1);
    });

    test('a count inside the same month is kept', () async {
      storage.record = storedRecord(usedFiles: 7, at: DateTime(2026, 7, 2));
      final UsageQuotaRepoImpl repo = buildRepo();

      await repo.refresh();

      expect(repo.usageListenable.value.usedFiles, 7);
    });

    test('the count refills when the month turns', () async {
      storage.record = storedRecord(usedFiles: 10, at: DateTime(2026, 7, 31));
      now = DateTime(2026, 8);
      final UsageQuotaRepoImpl repo = buildRepo();

      await repo.refresh();

      expect(repo.usageListenable.value.usedFiles, 0);
      expect(
        repo.usageListenable.value.period,
        const QuotaPeriod(year: 2026, month: 8),
      );
    });

    test('a clock wound back to a spent month does not replay it', () async {
      storage.record = storedRecord(usedFiles: 9, at: DateTime(2026, 7, 20));
      // Someone has set the device back a month to get a fresh ten files.
      now = DateTime(2026, 6);
      final UsageQuotaRepoImpl repo = buildRepo();

      await repo.refresh();

      expect(repo.usageListenable.value.usedFiles, 9);
      expect(
        repo.usageListenable.value.period,
        const QuotaPeriod(year: 2026, month: 7),
      );
    });
  });

  group('consume', () {
    test('files add up within a month', () async {
      final UsageQuotaRepoImpl repo = buildRepo();

      await repo.consume(3);
      await repo.consume(2);

      expect(repo.usageListenable.value.usedFiles, 5);
      expect(storage.record?.usage.usedFiles, 5);
    });

    test('a run that produced nothing writes nothing', () async {
      final UsageQuotaRepoImpl repo = buildRepo();

      await repo.consume(0);

      expect(storage.writeCount, 0);
      expect(repo.usageListenable.value.usedFiles, 0);
    });

    test('overlapping runs cannot lose a count', () async {
      final UsageQuotaRepoImpl repo = buildRepo();

      // Read-modify-write, three times at once: without the queue inside the
      // repo the last writer would win and two files would be free.
      await Future.wait<void>(<Future<void>>[
        repo.consume(1),
        repo.consume(1),
        repo.consume(1),
      ]);

      expect(repo.usageListenable.value.usedFiles, 3);
    });

    test('consuming after the month turned starts from the new count',
        () async {
      storage.record = storedRecord(usedFiles: 8, at: DateTime(2026, 7, 31));
      now = DateTime(2026, 8, 1, 9);
      final UsageQuotaRepoImpl repo = buildRepo();

      await repo.consume(2);

      expect(repo.usageListenable.value.usedFiles, 2);
    });

    test('storage that will not answer still lets the user convert', () async {
      final UsageQuotaRepoImpl repo = UsageQuotaRepoImpl(
        storage: BrokenQuotaStorage(),
        now: () => now,
      );

      await repo.refresh();
      await repo.consume(2);

      // In memory only, and gone at the next launch — but nothing threw, and
      // the conversion went ahead.
      expect(repo.usageListenable.value.usedFiles, 2);
    });

    test('listeners hear every change', () async {
      final UsageQuotaRepoImpl repo = buildRepo();
      final List<int> seen = <int>[];
      repo.usageListenable.addListener(
        () => seen.add(repo.usageListenable.value.usedFiles),
      );

      await repo.consume(1);
      await repo.consume(4);

      expect(seen, <int>[1, 5]);
    });
  });
}
