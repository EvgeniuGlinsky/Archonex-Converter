import 'dart:io';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';

/// Test material built on the device, so nothing large lives in the repository.
class SyntheticSource {
  const SyntheticSource._();

  static const String _directoryPrefix = 'archonex_probe_';

  /// Bitrate the synthetic clips are encoded at, in bits per second.
  ///
  /// 50 Mbit/s is a plausible high quality 1080p rate, and it makes the
  /// duration needed for a given file size short enough that generating a
  /// multi-gigabyte source is minutes rather than hours.
  static const int _bitsPerSecond = 50 * 1000 * 1000;

  static const int _bitsPerByte = 8;

  /// A file of exactly [bytes] with no content worth reading.
  ///
  /// Created by extending rather than writing: the length is what the memory
  /// probe needs, and most filesystems keep the extent sparse, so a 4 GB probe
  /// does not need 4 GB of free disk to run. It measures memory, never storage.
  static Future<File> blankFile(int bytes) async {
    final Directory directory = await _directory();
    final File file = File('${directory.path}${Platform.pathSeparator}'
        'blank_$bytes.bin');

    final RandomAccessFile handle = await file.open(mode: FileMode.write);
    try {
      await handle.truncate(bytes);
    } finally {
      await handle.close();
    }

    return file;
  }

  /// A real, decodable H.264 clip of roughly [targetBytes].
  ///
  /// `ultrafast` keeps generation from dominating the run; the point is a file
  /// of a given size that FFmpeg will genuinely have to decode, not a
  /// well-encoded one. Returns `null` if generation failed, so the caller can
  /// record "not measured" rather than a false ceiling.
  static Future<File?> video({required int targetBytes}) async {
    final Directory directory = await _directory();
    final String path = '${directory.path}${Platform.pathSeparator}'
        'source_$targetBytes.mp4';
    final int seconds = (targetBytes * _bitsPerByte / _bitsPerSecond).ceil();

    final FFmpegSession session = await FFmpegKit.executeWithArguments(
      <String>[
        '-y',
        '-f',
        'lavfi',
        '-i',
        'testsrc2=size=1920x1080:rate=30',
        '-t',
        '$seconds',
        '-c:v',
        'libx264',
        '-preset',
        'ultrafast',
        '-b:v',
        '$_bitsPerSecond',
        '-pix_fmt',
        'yuv420p',
        path,
      ],
    );

    final ReturnCode? code = await session.getReturnCode();
    if (!ReturnCode.isSuccess(code)) {
      return null;
    }

    final File file = File(path);

    return await file.exists() ? file : null;
  }

  static Future<void> delete(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } on FileSystemException {
      // A leftover probe file is not worth failing the run over.
    }
  }

  static Future<Directory> _directory() =>
      Directory.systemTemp.createTemp(_directoryPrefix);
}
