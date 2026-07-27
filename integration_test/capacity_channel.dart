import 'dart:io';

import 'package:flutter/services.dart';

/// What the device can hold, as reported by the platform.
///
/// Every field is nullable because only Android answers all of them; on
/// desktop the numbers that matter are disk-only and come from the shell.
class DeviceCapacityReport {
  const DeviceCapacityReport({
    this.memoryClassMb,
    this.largeMemoryClassMb,
    this.totalRamBytes,
    this.availableRamBytes,
    this.runtimeMaxHeapBytes,
    this.freeStorageBytes,
    this.totalStorageBytes,
  });

  /// ART heap ceiling in MB. A `byte[]` past this throws, whatever the RAM.
  final int? memoryClassMb;

  /// What the ceiling would become with `android:largeHeap="true"`.
  final int? largeMemoryClassMb;

  final int? totalRamBytes;
  final int? availableRamBytes;
  final int? runtimeMaxHeapBytes;
  final int? freeStorageBytes;
  final int? totalStorageBytes;

  Map<String, Object?> toJson() => <String, Object?>{
        'memoryClassMb': memoryClassMb,
        'largeMemoryClassMb': largeMemoryClassMb,
        'totalRamBytes': totalRamBytes,
        'availableRamBytes': availableRamBytes,
        'runtimeMaxHeapBytes': runtimeMaxHeapBytes,
        'freeStorageBytes': freeStorageBytes,
        'totalStorageBytes': totalStorageBytes,
      };
}

/// Bridge to the native side of the capacity probe.
///
/// Only Android implements the channel (see `MainActivity.kt`); everywhere else
/// the calls fall back to what can be learned from the shell, and to `null`
/// where nothing can.
class CapacityChannel {
  const CapacityChannel();

  static const MethodChannel _channel = MethodChannel('archonex/capacity');

  Future<DeviceCapacityReport> deviceReport() async {
    if (Platform.isAndroid) {
      final Map<Object?, Object?>? raw =
          await _channel.invokeMethod<Map<Object?, Object?>>('deviceReport');

      if (raw != null) {
        int? asInt(String key) => (raw[key] as num?)?.toInt();

        return DeviceCapacityReport(
          memoryClassMb: asInt('memoryClassMb'),
          largeMemoryClassMb: asInt('largeMemoryClassMb'),
          totalRamBytes: asInt('totalRamBytes'),
          availableRamBytes: asInt('availableRamBytes'),
          runtimeMaxHeapBytes: asInt('runtimeMaxHeapBytes'),
          freeStorageBytes: asInt('freeInternalStorageBytes'),
          totalStorageBytes: asInt('totalInternalStorageBytes'),
        );
      }
    }

    return DeviceCapacityReport(freeStorageBytes: await _freeSpaceFromShell());
  }

  /// Pushes [bytes] across a real method channel and returns how many arrived.
  ///
  /// This is the automatable stand-in for saving: `FilePicker.saveFile` opens a
  /// system dialog that an integration test cannot drive, but the part of it
  /// that breaks on a large result — a whole `Uint8List` encoded, transferred
  /// and re-allocated as a platform array — is exactly what happens here.
  ///
  /// Returns `null` where the channel is not implemented, so the probe can say
  /// "not measured" instead of inventing a number.
  Future<int?> probeByteTransfer(Uint8List bytes) async {
    if (!Platform.isAndroid) {
      return null;
    }

    final int? received =
        await _channel.invokeMethod<int>('probeByteTransfer', bytes);

    return received;
  }

  /// Free bytes on the volume holding the temp directory, via the OS shell.
  ///
  /// `dart:io` exposes no free-space API, and pulling in a package for one
  /// number a diagnostic needs is not worth it.
  Future<int?> _freeSpaceFromShell() async {
    final String path = Directory.systemTemp.path;

    try {
      if (Platform.isWindows) {
        final String drive = path.substring(0, 1);
        final ProcessResult result = await Process.run('powershell', <String>[
          '-NoProfile',
          '-Command',
          '(Get-PSDrive $drive).Free',
        ]);

        return int.tryParse(result.stdout.toString().trim());
      }

      // df -k reports 1K blocks; the fourth column of the second line is free.
      final ProcessResult result = await Process.run('df', <String>['-k', path]);
      final List<String> lines = result.stdout.toString().trim().split('\n');
      if (lines.length < 2) {
        return null;
      }

      final List<String> columns = lines[1].split(RegExp(r'\s+'));
      if (columns.length < 4) {
        return null;
      }

      final int? kilobytes = int.tryParse(columns[3]);

      return kilobytes == null ? null : kilobytes * 1024;
    } on ProcessException {
      return null;
    }
  }
}
