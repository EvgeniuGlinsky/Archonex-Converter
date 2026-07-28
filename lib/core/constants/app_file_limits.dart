import 'package:flutter/foundation.dart';

/// Size ceilings applied to every file the user hands to the app.
///
/// [maxUploadBytes]/[maxResultBytes] are the real technical ceiling of the
/// platform — the app offers the full amount rather than a discounted
/// fraction of it, so there is no size-based free/paid split.
///
/// The ceiling is per platform because the binding constraint is per platform.
/// On desktop the result is copied by the OS and nothing is ever resident, so
/// there is no architectural ceiling at all. On Android and iOS
/// `file_picker.saveFile` takes the bytes rather than a path, so the whole
/// result has to fit in memory at once — offering the raw technical maximum
/// there trades away the safety margin that used to guard against an
/// out-of-memory crash on real devices near that ceiling.
/// `integration_test/capacity_probe_test.dart` exists to measure a real,
/// per-device safe number if that risk shows up in practice.
class AppFileLimits {
  const AppFileLimits._();

  static const int bytesInKilobyte = 1024;
  static const int bytesInMegabyte = bytesInKilobyte * bytesInKilobyte;
  static const int bytesInGigabyte = bytesInMegabyte * bytesInKilobyte;
  static const int bytesInTerabyte = bytesInGigabyte * bytesInKilobyte;

  /// Hard ceiling for a source file on the current platform.
  static int get maxUploadBytes => _tier.technicalMaxBytes;

  /// Hard ceiling for a produced file. The same number: on the platforms where
  /// saving is the bottleneck, the output is what has to fit, and an output can
  /// easily come out larger than the input it came from.
  static int get maxResultBytes => _tier.technicalMaxBytes;

  /// How many files one batch conversion may carry.
  ///
  /// Unlike the byte ceilings this one is a product choice on every platform:
  /// files are converted one at a time, so nothing in the stack caps the count.
  /// What it does bound is the temporary directory a batch leaves behind and
  /// the number of save dialogs the fallback path can ask for, both of which
  /// stop being reasonable long before anything breaks.
  static int get maxBatchFiles => _tier.maxBatchFiles;

  /// What the stack cannot go past on this platform — the same number as
  /// [maxUploadBytes]/[maxResultBytes], kept as its own name for the call
  /// sites that talk about the physical ceiling specifically.
  static int get technicalMaxBytes => _tier.technicalMaxBytes;

  /// Human readable form of [maxUploadBytes], used in copy.
  ///
  /// Derived rather than written out: a hand-typed label is how copy ends up
  /// promising a limit the code does not enforce.
  static String get maxUploadLabel => _format(maxUploadBytes);

  static String _format(int bytes) {
    if (bytes % bytesInTerabyte == 0) {
      return '${bytes ~/ bytesInTerabyte} TB';
    }
    return bytes % bytesInGigabyte == 0
        ? '${bytes ~/ bytesInGigabyte} GB'
        : '${bytes ~/ bytesInMegabyte} MB';
  }

  static _CapacityTier get _tier {
    if (kIsWeb) {
      return _CapacityTier.unsupported;
    }

    return switch (defaultTargetPlatform) {
      TargetPlatform.android => _CapacityTier.android,
      TargetPlatform.iOS => _CapacityTier.iOS,
      // Linux belongs here despite shipping no FFmpeg: this answers how large a
      // file can be saved, not which engines exist. Its save path is the same
      // OS-level copy the other desktops use, and the PDF converter — which
      // needs no FFmpeg — really does run there. Whether a given engine is
      // available is a separate question each repository answers for itself,
      // see `FfmpegImageConverterRepo.isSupported`.
      TargetPlatform.linux ||
      TargetPlatform.windows ||
      TargetPlatform.macOS =>
        _CapacityTier.desktop,
      TargetPlatform.fuchsia => _CapacityTier.unsupported,
    };
  }
}

/// One platform's ceiling, and where it comes from.
@immutable
class _CapacityTier {
  const _CapacityTier({
    required this.technicalMaxBytes,
    required this.maxBatchFiles,
  });

  /// Android hands the result to the platform as a Java `byte[]`, whose length
  /// is a signed 32-bit int — 2 GiB − 1, before device RAM is even considered.
  static const _CapacityTier android = _CapacityTier(
    technicalMaxBytes: 2 * AppFileLimits.bytesInGigabyte,
    maxBatchFiles: _mobileBatchFiles,
  );

  /// iOS carries the bytes as `NSData`, so the 32-bit array length does not
  /// apply; the binding hard limit is Flutter's own message codec, whose
  /// `writeSize` asserts the payload is at most `0xffffffff` — 4 GiB − 1.
  static const _CapacityTier iOS = _CapacityTier(
    technicalMaxBytes: 4 * AppFileLimits.bytesInGigabyte,
    maxBatchFiles: _mobileBatchFiles,
  );

  /// Windows and macOS stream: FFmpeg reads the source by path and the result
  /// is copied by the OS, so nothing is ever resident and there is no
  /// architectural ceiling at all — only free disk. The number below is not a
  /// real bound, just a figure no real file will ever reach.
  static const _CapacityTier desktop = _CapacityTier(
    technicalMaxBytes: AppFileLimits.bytesInTerabyte,
    maxBatchFiles: _desktopBatchFiles,
  );

  /// Web and Linux have no conversion engine, so no file is convertible. The
  /// screen says so up front; this keeps the number honest if it is ever read.
  static const _CapacityTier unsupported = _CapacityTier(
    technicalMaxBytes: 0,
    maxBatchFiles: 0,
  );

  /// A phone batch is bounded by the fallback save path more than by anything
  /// technical: if the chosen folder turns out to be unwritable the app falls
  /// back to one dialog per file, and thirty dialogs is already a lot to ask.
  static const int _mobileBatchFiles = 30;

  /// Desktop never needs the fallback — the OS copies into the chosen folder —
  /// so the count is bounded only by how long a sequential run stays sensible.
  static const int _desktopBatchFiles = 100;

  final int technicalMaxBytes;
  final int maxBatchFiles;
}
