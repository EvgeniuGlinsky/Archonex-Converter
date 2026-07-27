import 'package:flutter/foundation.dart';

/// Size ceilings applied to every file the user hands to the app.
///
/// Two different numbers live here and they must not be confused:
///
/// * [_CapacityTier.technicalMaxBytes] — what the stack physically cannot go
///   past. Each one is a documented fact, not an estimate.
/// * [maxUploadBytes] — what the app actually offers, set at [freeTierShare]
///   of the technical maximum and rounded down to a figure a user can hold in
///   their head. Headroom is deliberate: the technical maximum is where things
///   break, not where they work well.
///
/// The ceiling is per platform because the binding constraint is per platform.
/// On desktop the result is copied by the OS and nothing is ever resident; on
/// Android and iOS `file_picker.saveFile` takes the bytes rather than a path,
/// so the whole result has to fit in memory at once.
class AppFileLimits {
  const AppFileLimits._();

  static const int bytesInKilobyte = 1024;
  static const int bytesInMegabyte = bytesInKilobyte * bytesInKilobyte;
  static const int bytesInGigabyte = bytesInMegabyte * bytesInKilobyte;

  /// Share of the technical maximum offered before any paid tier applies.
  static const double freeTierShare = 0.3;

  /// Hard ceiling for a source file on the current platform.
  static int get maxUploadBytes => _tier.limitBytes;

  /// Hard ceiling for a produced file. The same number: on the platforms where
  /// saving is the bottleneck, the output is what has to fit, and an output can
  /// easily come out larger than the input it came from.
  static int get maxResultBytes => _tier.limitBytes;

  /// What the stack cannot go past on this platform, whatever the app offers.
  static int get technicalMaxBytes => _tier.technicalMaxBytes;

  /// `true` where the ceiling is ours rather than the platform's, so a paid
  /// tier can drop it altogether instead of merely raising it.
  static bool get isPhantomLimit => _tier.isPhantomLimit;

  /// Human readable form of [maxUploadBytes], used in copy.
  ///
  /// Derived rather than written out: a hand-typed label is how copy ends up
  /// promising a limit the code does not enforce.
  static String get maxUploadLabel => _format(maxUploadBytes);

  static String _format(int bytes) => bytes % bytesInGigabyte == 0
      ? '${bytes ~/ bytesInGigabyte} GB'
      : '${bytes ~/ bytesInMegabyte} MB';

  static _CapacityTier get _tier {
    if (kIsWeb) {
      return _CapacityTier.unsupported;
    }

    return switch (defaultTargetPlatform) {
      TargetPlatform.android => _CapacityTier.android,
      TargetPlatform.iOS => _CapacityTier.iOS,
      TargetPlatform.windows ||
      TargetPlatform.macOS =>
        _CapacityTier.desktop,
      // Linux ships no FFmpeg engine, so nothing is convertible there.
      TargetPlatform.linux || TargetPlatform.fuchsia => _CapacityTier.unsupported,
    };
  }
}

/// One platform's ceiling, and where its technical maximum comes from.
@immutable
class _CapacityTier {
  const _CapacityTier({
    required this.technicalMaxBytes,
    required this.limitBytes,
    this.isPhantomLimit = false,
  });

  /// Android hands the result to the platform as a Java `byte[]`, whose length
  /// is a signed 32-bit int — 2 GiB − 1, before device RAM is even considered.
  ///
  /// 30% is 614 MB, rounded down to 512 MB. Note this is still optimistic:
  /// saving a 512 MB result needs roughly 2–3× that resident across the Dart
  /// heap and the ART heap, and `android:largeHeap` is not set. The capacity
  /// probe exists to replace this with a measured number.
  static const _CapacityTier android = _CapacityTier(
    technicalMaxBytes: 2 * AppFileLimits.bytesInGigabyte,
    limitBytes: 512 * AppFileLimits.bytesInMegabyte,
  );

  /// iOS carries the bytes as `NSData`, so the 32-bit array length does not
  /// apply; the binding hard limit is Flutter's own message codec, whose
  /// `writeSize` asserts the payload is at most `0xffffffff` — 4 GiB − 1.
  ///
  /// 30% is 1.2 GiB, rounded down to 1 GB.
  static const _CapacityTier iOS = _CapacityTier(
    technicalMaxBytes: 4 * AppFileLimits.bytesInGigabyte,
    limitBytes: AppFileLimits.bytesInGigabyte,
  );

  /// Windows and macOS stream: FFmpeg reads the source by path and the result
  /// is copied by the OS, so nothing is ever resident and there is **no
  /// architectural ceiling at all** — only free disk.
  ///
  /// The limit here is therefore a phantom one: a product choice, not a
  /// measurement, and the number to lift outright rather than raise when the
  /// paid tier arrives. 4 GB was picked because it is the largest single file
  /// FAT32 can hold, so a result saved to a USB stick still lands, and because
  /// a 1080p H.264 source only reaches it after roughly two and a half hours.
  /// [technicalMaxBytes] carries the same figure only so the ratio stays
  /// readable; nothing enforces it.
  static const _CapacityTier desktop = _CapacityTier(
    technicalMaxBytes: 16 * AppFileLimits.bytesInGigabyte,
    limitBytes: 4 * AppFileLimits.bytesInGigabyte,
    isPhantomLimit: true,
  );

  /// Web and Linux have no conversion engine, so no file is convertible. The
  /// screen says so up front; this keeps the number honest if it is ever read.
  static const _CapacityTier unsupported = _CapacityTier(
    technicalMaxBytes: 0,
    limitBytes: 0,
  );

  final int technicalMaxBytes;
  final int limitBytes;

  /// `true` where nothing in the stack actually enforces a ceiling, so the
  /// limit is ours to lift entirely rather than to raise.
  final bool isPhantomLimit;
}
