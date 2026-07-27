import 'package:archonex/project_files/features/media_converter/domain/models/conversion_failure.dart';

/// Turns FFmpeg's log output into a failure the screen can explain.
///
/// A non-zero exit code on its own only ever produces "conversion failed",
/// which tells the user nothing about a video with no sound track or a
/// half-downloaded file. FFmpeg does say which of those happened — it says it
/// in the log — so the log is kept and read.
///
/// Only a tail is retained: a long run prints megabytes and none of the early
/// output matters once the thing has failed.
class FfmpegErrorClassifier {
  FfmpegErrorClassifier();

  /// Enough to hold the last few messages, which is where the cause lands.
  static const int _maxLength = 2048;

  static const List<String> _storageMarkers = <String>[
    'no space left on device',
    'not enough space',
  ];

  static const List<String> _missingStreamMarkers = <String>[
    'does not contain any stream',
    'matches no streams',
  ];

  static const List<String> _corruptSourceMarkers = <String>[
    'invalid data found when processing input',
    'moov atom not found',
    'could not find codec parameters',
  ];

  final StringBuffer _buffer = StringBuffer();

  void add(String fragment) {
    _buffer.write(fragment.toLowerCase());

    if (_buffer.length <= _maxLength) {
      return;
    }

    final String tail = _buffer.toString();
    _buffer
      ..clear()
      ..write(tail.substring(tail.length - _maxLength));
  }

  /// The specific failure the log points at, or `null` when it says nothing
  /// useful and the generic engine failure is the honest answer.
  ConversionFailure? classify() {
    final String log = _buffer.toString();

    bool mentions(List<String> markers) => markers.any(log.contains);

    if (mentions(_storageMarkers)) {
      return const InsufficientStorageFailure();
    }
    if (mentions(_missingStreamMarkers)) {
      return const NoAudioTrackFailure();
    }
    if (mentions(_corruptSourceMarkers)) {
      return const CorruptSourceFailure();
    }

    return null;
  }
}
