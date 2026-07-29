import 'package:flutter/foundation.dart';

/// Size ceilings applied to every file the user hands to the app, and how many
/// of them one run may carry.
///
/// None of this is a free/paid split: where a ceiling exists it is the real
/// technical maximum of the platform, offered in full rather than as a
/// discounted fraction.
///
/// **The source and the result are bounded by different things**, which is why
/// [maxUploadBytes] and [maxResultBytes] are separate numbers rather than one.
/// FFmpeg reads a source by path on every platform, so nothing is ever resident
/// while reading and no platform has a real ceiling on the input. Saving is
/// where they diverge, and iOS is now the only place they do: `saveFile` throws
/// there without `bytes`, so the whole output has to be held at once — see
/// `IoFileSaver`, which catches the `OutOfMemoryError` this produces. Desktop
/// and Android both copy the result into a folder instead, and a copy holds
/// nothing, so neither has a ceiling on either side.
/// `integration_test/capacity_probe_test.dart` exists to measure a real,
/// per-device safe number if the margin turns out to matter in practice.
class AppFileLimits {
  const AppFileLimits._();

  static const int bytesInKilobyte = 1024;
  static const int bytesInMegabyte = bytesInKilobyte * bytesInKilobyte;
  static const int bytesInGigabyte = bytesInMegabyte * bytesInKilobyte;
  static const int bytesInTerabyte = bytesInGigabyte * bytesInKilobyte;

  /// A batch with no ceiling on how many files it carries.
  ///
  /// Its own name, like `AppQuotaLimits.unlimited`, so no call site has to know
  /// that "unlimited" is spelled with a sentinel. Note that zero is *not* this:
  /// a platform with no engine allows no files at all.
  static const int unlimitedBatch = -1;

  /// Hard ceiling for a source file on the current platform.
  static int get maxUploadBytes => _tier.maxSourceBytes;

  /// Hard ceiling for a produced file, which is what saving has to carry.
  static int get maxResultBytes => _tier.technicalMaxBytes;

  /// How many files one batch conversion may carry, or [unlimitedBatch].
  ///
  /// Unlike the byte ceilings this one is a product choice: files are converted
  /// one at a time, so nothing in the stack caps the count. What it does bound
  /// is the temporary directory a batch leaves behind and the number of save
  /// dialogs the fallback path can ask for.
  static int get maxBatchFiles => _tier.maxBatchFiles;

  /// Whether [maxBatchFiles] is a number worth enforcing or announcing.
  static bool get isBatchLimited => maxBatchFiles != unlimitedBatch;

  /// Whether picking a file can be refused for its size alone.
  ///
  /// False where the source ceiling is only a figure no real file reaches. The
  /// guards stay in place either way — they simply never fire — but copy has to
  /// know, or a screen promises a limit that does not exist.
  static bool get limitsSourceSize => maxUploadBytes < bytesInTerabyte;

  /// Whether saving can be refused for the result's size alone.
  ///
  /// The pair of [limitsSourceSize], and read for the same reason: with both
  /// false there is no ceiling left to announce, and `ConverterLimitsUi` says
  /// nothing rather than naming a number no file will reach.
  static bool get limitsResultSize => maxResultBytes < bytesInTerabyte;

  /// What the stack cannot go past on this platform, which is the same number
  /// as [maxResultBytes] — kept as its own name for the call sites that talk
  /// about the physical ceiling specifically.
  static int get technicalMaxBytes => _tier.technicalMaxBytes;

  /// Human readable form of [maxUploadBytes], used in copy.
  ///
  /// Derived rather than written out: a hand-typed label is how copy ends up
  /// promising a limit the code does not enforce.
  static String get maxUploadLabel => _format(maxUploadBytes);

  /// Human readable form of [maxResultBytes]. Only worth showing where
  /// [limitsResultSize] holds, which today is iOS alone.
  static String get maxResultLabel => _format(maxResultBytes);

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
    required this.maxSourceBytes,
    required this.technicalMaxBytes,
    required this.maxBatchFiles,
  });

  /// Android has no ceiling left. FFmpeg reads the source by path and
  /// `IoFileSaver.saveOne` copies the result into a folder the user picks, so
  /// nothing is ever resident on either side and both figures below are the
  /// desktop trick — a number no real file reaches.
  ///
  /// The result used to be bounded at 2 GiB, the length of the Java `byte[]` the
  /// platform channel carries, because a single file was saved by handing its
  /// bytes to `saveFile`. That is still what the fallback does when a
  /// storage-access URI turns out to be unwritable, and it still reports
  /// `ResultTooLargeToSaveFailure` when the memory runs out — but a ceiling that
  /// only one rare path has is not a ceiling to check before converting.
  /// Keeping 2 GiB as the pre-check was rejected for refusing a file the folder
  /// route saves without complaint.
  ///
  /// The source used to carry the result's number as a proxy, on the reasoning
  /// that an output can come out larger than its input. It refused a five
  /// gigabyte video outright rather than letting it be compressed into
  /// something savable, which is the more common thing to want.
  static const _CapacityTier android = _CapacityTier(
    maxSourceBytes: AppFileLimits.bytesInTerabyte,
    technicalMaxBytes: AppFileLimits.bytesInTerabyte,
    maxBatchFiles: AppFileLimits.unlimitedBatch,
  );

  /// iOS carries the bytes as `NSData`, so the 32-bit array length does not
  /// apply; the binding hard limit is Flutter's own message codec, whose
  /// `writeSize` asserts the payload is at most `0xffffffff` — 4 GiB − 1.
  static const _CapacityTier iOS = _CapacityTier(
    maxSourceBytes: 4 * AppFileLimits.bytesInGigabyte,
    technicalMaxBytes: 4 * AppFileLimits.bytesInGigabyte,
    maxBatchFiles: _mobileBatchFiles,
  );

  /// Windows and macOS stream: FFmpeg reads the source by path and the result
  /// is copied by the OS, so nothing is ever resident and there is no
  /// architectural ceiling at all — only free disk. The number below is not a
  /// real bound, just a figure no real file will ever reach.
  static const _CapacityTier desktop = _CapacityTier(
    maxSourceBytes: AppFileLimits.bytesInTerabyte,
    technicalMaxBytes: AppFileLimits.bytesInTerabyte,
    maxBatchFiles: _desktopBatchFiles,
  );

  /// Web and Fuchsia have no file system to write into, so no file is
  /// convertible. The screen says so up front; this keeps the number honest if
  /// it is ever read. Linux is deliberately not here — see [AppFileLimits._tier].
  /// Zero rather than [AppFileLimits.unlimitedBatch]: nothing is allowed here,
  /// which is the opposite of no ceiling.
  static const _CapacityTier unsupported = _CapacityTier(
    maxSourceBytes: 0,
    technicalMaxBytes: 0,
    maxBatchFiles: 0,
  );

  /// A phone batch is bounded by the fallback save path more than by anything
  /// technical: if the chosen folder turns out to be unwritable the app falls
  /// back to one dialog per file, and thirty dialogs is already a lot to ask.
  /// Android does without it because that fallback stops at the first dialog
  /// the user closes — see `IoFileSaver._saveOneByOne` — so a long batch costs
  /// one refusal rather than a hundred.
  static const int _mobileBatchFiles = 30;

  /// Desktop never needs the fallback — the OS copies into the chosen folder —
  /// so the count is bounded only by how long a sequential run stays sensible.
  static const int _desktopBatchFiles = 100;

  final int maxSourceBytes;
  final int technicalMaxBytes;
  final int maxBatchFiles;
}
