import 'package:flutter/foundation.dart';

import 'package:archonex_converter/project_files/features/usage_quota/domain/models/quota_period.dart';
import 'package:archonex_converter/project_files/features/usage_quota/domain/models/quota_record.dart';
import 'package:archonex_converter/project_files/features/usage_quota/domain/models/quota_usage.dart';
import 'package:archonex_converter/project_files/features/usage_quota/domain/quota_storage.dart';
import 'package:archonex_converter/project_files/features/usage_quota/domain/usage_quota_repo.dart';

/// The monthly counter: every rule about periods and clocks lives here, and
/// [QuotaStorage] only holds what those rules produced.
///
/// [now] is injectable because month boundaries are otherwise untestable —
/// and because the tests would have to wait for one.
///
/// **What the clock defence does and does not cover.** A clock moved backwards
/// is ignored: [QuotaRecord.lastSeen] wins, so winding the date back cannot
/// replay a period that was already spent. A clock moved *forwards* does grant
/// a fresh count — but only once, since the device is then pinned to that
/// later date and cannot rewind to reach the month again. Closing that hole
/// entirely needs a server, which an offline app does not have.
class UsageQuotaRepoImpl implements UsageQuotaRepo {
  UsageQuotaRepoImpl({
    required QuotaStorage storage,
    DateTime Function()? now,
  })  : _storage = storage,
        _now = now ?? DateTime.now {
    _usage = ValueNotifier<QuotaUsage>(QuotaUsage.emptyAt(_now()));
  }

  final QuotaStorage _storage;
  final DateTime Function() _now;

  late final ValueNotifier<QuotaUsage> _usage;

  /// Both public methods are read-modify-write, and two of them overlapping
  /// would drop a count, so they run one after another.
  Future<void> _pending = Future<void>.value();

  @override
  ValueListenable<QuotaUsage> get usageListenable => _usage;

  @override
  Future<void> refresh() => _serialized(() async {
        final QuotaRecord record = _rolledOver(await _read());

        await _write(record);
        _usage.value = record.usage;
      });

  @override
  Future<void> consume(int fileCount) {
    // A run that produced nothing costs nothing. Guarding here rather than at
    // the call sites keeps "converted zero files" from writing to disk.
    if (fileCount <= 0) {
      return Future<void>.value();
    }

    return _serialized(() async {
      final QuotaRecord current = _rolledOver(await _read());
      final QuotaRecord next = QuotaRecord(
        usage: current.usage.plus(fileCount),
        lastSeen: current.lastSeen,
      );

      await _write(next);
      _usage.value = next.usage;
    });
  }

  /// Storage that will not answer is treated as storage that agrees with what
  /// is already in memory.
  ///
  /// A device with unreadable preferences — or a build with no preferences
  /// plugin at all — still gets to convert, with a count that lasts as long as
  /// the process does. Erring towards letting the user work is the right way
  /// round to fail for something that decides whether to charge them.
  Future<QuotaRecord?> _read() async {
    try {
      return await _storage.read();
    } catch (_) {
      return QuotaRecord(usage: _usage.value, lastSeen: _now());
    }
  }

  Future<void> _write(QuotaRecord record) async {
    try {
      await _storage.write(record);
    } catch (_) {
      return;
    }
  }

  /// [stored] brought up to the current period, or a fresh count when the
  /// month has turned — or when there is nothing stored at all.
  QuotaRecord _rolledOver(QuotaRecord? stored) {
    final DateTime now = _clockReading(stored?.lastSeen);
    final QuotaPeriod period = QuotaPeriod.of(now);
    final bool isSamePeriod = stored != null && stored.usage.period == period;

    return QuotaRecord(
      usage: isSamePeriod ? stored.usage : QuotaUsage.emptyAt(now),
      lastSeen: now,
    );
  }

  /// The later of the system clock and the last moment this device was seen
  /// at, so a clock wound backwards changes nothing.
  DateTime _clockReading(DateTime? lastSeen) {
    final DateTime now = _now();

    return lastSeen != null && now.isBefore(lastSeen) ? lastSeen : now;
  }

  Future<void> _serialized(Future<void> Function() action) {
    final Future<void> next = _pending.then((_) => action());
    // A failed write must not wedge the queue behind it.
    _pending = next.catchError((Object _) {});

    return next;
  }
}
