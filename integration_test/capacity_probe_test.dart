import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:archonex/core/constants/app_file_limits.dart';
import 'package:archonex/project_files/features/converter_shared/domain/models/converted_file.dart';
import 'package:archonex/project_files/features/converter_shared/domain/models/source_file.dart';
import 'package:archonex/project_files/features/media_converter/data/ffmpeg/ffmpeg_media_converter_repo.dart';
import 'package:archonex/project_files/features/media_converter/domain/models/conversion_settings.dart';
import 'package:archonex/project_files/features/media_converter/domain/models/conversion_update.dart';
import 'package:archonex/project_files/features/media_converter/domain/models/media_format.dart';

import 'capacity_channel.dart';
import 'capacity_report.dart';
import 'synthetic_source.dart';

/// Measures what this device can actually convert, as opposed to what the app
/// currently offers.
///
/// Run it per device and read the printed table:
///
/// ```
/// flutter test integration_test/capacity_probe_test.dart -d windows
/// flutter test integration_test/capacity_probe_test.dart -d <android-id>
/// ```
///
/// The three stages measure three different ceilings, and only one of them
/// binds:
///
/// * **transfer** — the result crossing into the platform to be saved. On
///   Android and iOS the whole file must be resident, so this is the ceiling
///   that decides the product limit.
/// * **conversion** — FFmpeg itself. 64-bit throughout; expected to be limited
///   by patience and disk, not by size.
/// * **storage** — free space, which a mobile run consumes at roughly twice the
///   source plus twice the result.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const CapacityChannel channel = CapacityChannel();
  const FfmpegMediaConverterRepo converter = FfmpegMediaConverterRepo();

  /// Caps both ladders, so a smoke run can prove the harness works without
  /// saturating a machine for half an hour:
  ///
  /// ```
  /// flutter test integration_test/capacity_probe_test.dart -d windows \
  ///   --dart-define=PROBE_MAX_MB=64
  /// ```
  const int maxRungMb = int.fromEnvironment('PROBE_MAX_MB', defaultValue: 4096);

  /// Sizes in MB. Doubling means one extra step tells us the answer is between
  /// two adjacent rungs, which is precise enough to set a product limit.
  final List<int> ladderMb = <int>[64, 128, 256, 512, 1024, 2048, 4096]
      .where((size) => size <= maxRungMb)
      .toList();

  /// Sources big enough to be interesting without making a run take an hour.
  final List<int> conversionLadderMb = <int>[64, 256, 1024]
      .where((size) => size <= maxRungMb)
      .toList();

  /// Only Android and iOS route the result through memory to save it. Desktop
  /// hands the OS two paths and copies, so loading gigabytes here would measure
  /// a code path that does not exist and would do it on the developer's own
  /// machine.
  final bool transfersThroughMemory = Platform.isAndroid || Platform.isIOS;

  late CapacityReport report;

  setUpAll(() => report = CapacityReport());

  tearDownAll(() async {
    // ignore: avoid_print — the printed table is the deliverable of this test.
    print(report.render());
    await report.writeToDisk();
  });

  testWidgets('device reports what it can hold', (WidgetTester tester) async {
    final DeviceCapacityReport device = await channel.deviceReport();
    report.device = device;

    // Nothing to assert: on desktop most of this is legitimately null. The
    // numbers are the output.
    expect(report, isNotNull);
  });

  testWidgets(
    'transfer ceiling — the size at which saving stops working',
    (WidgetTester tester) async {
      if (!transfersThroughMemory) {
        report.addTransfer(0, LadderOutcome.notApplicable);

        return;
      }

      for (final int sizeMb in ladderMb) {
        final int bytes = sizeMb * AppFileLimits.bytesInMegabyte;
        final File file = await SyntheticSource.blankFile(bytes);

        try {
          final Uint8List loaded = await file.readAsBytes();
          report.addTransfer(sizeMb, LadderOutcome.readOk);

          final int? received = await channel.probeByteTransfer(loaded);
          report.addTransfer(
            sizeMb,
            received == null
                ? LadderOutcome.notMeasured
                : received == bytes
                    ? LadderOutcome.ok
                    : LadderOutcome.failed,
          );
        } on OutOfMemoryError {
          report.addTransfer(sizeMb, LadderOutcome.outOfMemory);
          break;
        } on Object catch (error) {
          report.addTransfer(sizeMb, LadderOutcome.failed, detail: '$error');
          break;
        } finally {
          await SyntheticSource.delete(file);
        }
      }
    },
    timeout: const Timeout(Duration(minutes: 30)),
  );

  testWidgets(
    'conversion ceiling — the size FFmpeg stops handling',
    (WidgetTester tester) async {
      for (final int sizeMb in conversionLadderMb) {
        final Stopwatch stopwatch = Stopwatch()..start();
        File? source;

        try {
          source = await SyntheticSource.video(
            targetBytes: sizeMb * AppFileLimits.bytesInMegabyte,
          );

          if (source == null) {
            report.addConversion(sizeMb, LadderOutcome.notMeasured);
            continue;
          }

          final ConvertedFile? result = await _convert(
            converter,
            source: source,
            target: MediaFormat.mkv,
          );

          stopwatch.stop();
          report.addConversion(
            sizeMb,
            result == null ? LadderOutcome.failed : LadderOutcome.ok,
            elapsed: stopwatch.elapsed,
            producedBytes: result?.sizeInBytes,
          );

          if (result != null) {
            await converter.discard(result);
          }
          if (result == null) {
            break;
          }
        } on Object catch (error) {
          report.addConversion(
            sizeMb,
            LadderOutcome.failed,
            detail: '$error',
          );
          break;
        } finally {
          if (source != null) {
            await SyntheticSource.delete(source);
          }
        }
      }
    },
    timeout: const Timeout(Duration(hours: 2)),
  );
}

/// Runs one conversion to completion, returning `null` if it failed.
Future<ConvertedFile?> _convert(
  FfmpegMediaConverterRepo converter, {
  required File source,
  required MediaFormat target,
}) async {
  final Completer<ConvertedFile?> completer = Completer<ConvertedFile?>();

  final Stream<ConversionUpdate> updates = converter
      .convert(
        source: SourceFile(
          name: source.uri.pathSegments.last,
          sizeInBytes: await source.length(),
          path: source.path,
        ),
        target: target,
        settings: const ConversionSettings(),
      )
      .updates;

  updates.listen(
    (update) {
      if (update is ConversionCompleted && !completer.isCompleted) {
        completer.complete(update.file);
      }
    },
    onError: (Object _) {
      if (!completer.isCompleted) {
        completer.complete(null);
      }
    },
    onDone: () {
      if (!completer.isCompleted) {
        completer.complete(null);
      }
    },
  );

  return completer.future;
}
