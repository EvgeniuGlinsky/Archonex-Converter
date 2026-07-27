import 'dart:io';

import 'package:archonex/core/constants/app_file_limits.dart';

import 'capacity_channel.dart';

/// What happened at one rung of a ladder.
enum LadderOutcome {
  ok('ok'),
  readOk('read ok'),
  outOfMemory('OUT OF MEMORY'),
  failed('FAILED'),
  notMeasured('not measured'),

  /// This platform never routes the file through memory, so there is nothing
  /// here to hit a ceiling — the save is an OS-level copy.
  notApplicable('n/a — streams to disk');

  const LadderOutcome(this.label);

  final String label;

  bool get isFailure =>
      this == LadderOutcome.outOfMemory || this == LadderOutcome.failed;
}

class LadderStep {
  LadderStep({
    required this.sizeMb,
    required this.outcome,
    this.elapsed,
    this.producedBytes,
    this.detail,
  });

  final int sizeMb;
  final LadderOutcome outcome;
  final Duration? elapsed;
  final int? producedBytes;
  final String? detail;
}

/// Collects the run and renders it as the table this whole exercise is for.
class CapacityReport {
  CapacityReport();

  static const String _fileName = 'archonex_capacity_report.md';

  DeviceCapacityReport? device;

  final List<LadderStep> _transfer = <LadderStep>[];
  final List<LadderStep> _conversion = <LadderStep>[];

  void addTransfer(int sizeMb, LadderOutcome outcome, {String? detail}) =>
      _transfer.add(
        LadderStep(sizeMb: sizeMb, outcome: outcome, detail: detail),
      );

  void addConversion(
    int sizeMb,
    LadderOutcome outcome, {
    Duration? elapsed,
    int? producedBytes,
    String? detail,
  }) =>
      _conversion.add(
        LadderStep(
          sizeMb: sizeMb,
          outcome: outcome,
          elapsed: elapsed,
          producedBytes: producedBytes,
          detail: detail,
        ),
      );

  /// Largest rung that fully succeeded, in MB, or `null` if none did.
  int? get maxTransferMb => _lastSuccess(_transfer);

  int? get maxConversionMb => _lastSuccess(_conversion);

  static int? _lastSuccess(List<LadderStep> steps) {
    int? best;
    for (final LadderStep step in steps) {
      if (step.outcome == LadderOutcome.ok) {
        best = step.sizeMb;
      }
    }

    return best;
  }

  String render() {
    final StringBuffer buffer = StringBuffer()
      ..writeln('# Archonex capacity probe')
      ..writeln()
      ..writeln('Platform: ${Platform.operatingSystem} '
          '${Platform.operatingSystemVersion}')
      ..writeln()
      ..writeln('Currently offered by the app on this platform: '
          '${AppFileLimits.maxUploadLabel}')
      ..writeln()
      ..writeln('## Device')
      ..writeln();

    final DeviceCapacityReport? reported = device;
    if (reported == null) {
      buffer.writeln('_not reported_');
    } else {
      buffer
        ..writeln('| Metric | Value |')
        ..writeln('|---|---|')
        ..writeln('| ART heap ceiling | ${_mb(reported.memoryClassMb)} |')
        ..writeln('| …with largeHeap | ${_mb(reported.largeMemoryClassMb)} |')
        ..writeln('| Total RAM | ${_gb(reported.totalRamBytes)} |')
        ..writeln('| Available RAM | ${_gb(reported.availableRamBytes)} |')
        ..writeln('| Dart/VM max heap | ${_gb(reported.runtimeMaxHeapBytes)} |')
        ..writeln('| Free storage | ${_gb(reported.freeStorageBytes)} |')
        ..writeln('| Total storage | ${_gb(reported.totalStorageBytes)} |');
    }

    buffer
      ..writeln()
      ..writeln('## Transfer ladder — the ceiling that binds')
      ..writeln()
      ..writeln('Reproduces what saving does to a result: read the whole file '
          'into memory, then hand it across the platform channel.')
      ..writeln();
    _renderLadder(buffer, _transfer);

    buffer
      ..writeln()
      ..writeln('## Conversion ladder')
      ..writeln();
    _renderLadder(buffer, _conversion, withTiming: true);

    buffer
      ..writeln()
      ..writeln('## Verdict')
      ..writeln()
      ..writeln('- Largest result that can be saved: ${_transferVerdict()}')
      ..writeln('- Largest source converted: '
          '${maxConversionMb == null ? 'none measured' : '$maxConversionMb MB'}');

    return buffer.toString();
  }

  void _renderLadder(
    StringBuffer buffer,
    List<LadderStep> steps, {
    bool withTiming = false,
  }) {
    if (steps.isEmpty) {
      buffer.writeln('_not run_');

      return;
    }

    buffer
      ..writeln('| Size | Outcome |'
          '${withTiming ? ' Elapsed | Produced |' : ''} Detail |')
      ..writeln('|---|---|${withTiming ? '---|---|' : ''}---|');

    for (final LadderStep step in steps) {
      final String timing = withTiming
          ? ' ${_duration(step.elapsed)} | ${_gb(step.producedBytes)} |'
          : '';
      buffer.writeln(
        '| ${step.sizeMb} MB | ${step.outcome.label} |$timing '
        '${step.detail ?? ''} |',
      );
    }
  }

  /// Writes the table next to the temp directory so it can be pulled off a
  /// device, since stdout from a phone is easy to lose.
  Future<void> writeToDisk() async {
    final File file = File(
      '${Directory.systemTemp.path}${Platform.pathSeparator}$_fileName',
    );

    try {
      await file.writeAsString(render());
    } on FileSystemException {
      // stdout already carries the table; the file is a convenience.
    }
  }

  bool get _streamsToDisk =>
      _transfer.any((step) => step.outcome == LadderOutcome.notApplicable);

  String _transferVerdict() {
    if (_streamsToDisk) {
      return 'unbounded — this platform copies the file, never loads it';
    }

    return maxTransferMb == null ? 'none measured' : '$maxTransferMb MB';
  }

  static String _mb(int? megabytes) =>
      megabytes == null ? '—' : '$megabytes MB';

  static String _gb(int? bytes) {
    if (bytes == null) {
      return '—';
    }
    if (bytes < AppFileLimits.bytesInGigabyte) {
      return '${(bytes / AppFileLimits.bytesInMegabyte).toStringAsFixed(1)} MB';
    }

    return '${(bytes / AppFileLimits.bytesInGigabyte).toStringAsFixed(2)} GB';
  }

  static String _duration(Duration? elapsed) =>
      elapsed == null ? '—' : '${elapsed.inSeconds} s';
}
