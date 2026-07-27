/// Reads the input length out of FFmpeg's own log output.
///
/// FFmpeg prints `Duration: 00:01:00.37, start: ...` while probing the input,
/// well before the first statistics tick. Taking the duration from there
/// avoids a separate FFprobe pass — one that reported nothing usable on
/// Windows — and works anywhere FFmpeg itself runs.
///
/// The catch is that the log callback does not deliver whole lines: FFmpeg
/// hands over each `av_log` argument separately, so `Duration: ` and
/// `00:01:00.37` arrive as two messages. Fragments are therefore accumulated
/// until the pattern matches across them.
class FfmpegDurationParser {
  FfmpegDurationParser();

  /// The duration header appears in the first few hundred characters. Once
  /// past this much output it is not coming, and buffering further would grow
  /// without bound for a long conversion.
  static const int _maxBufferLength = 4096;

  /// `Duration: N/A` is a legitimate answer for some inputs and simply never
  /// matches, which the UI renders as indeterminate progress.
  static final RegExp _pattern =
      RegExp(r'Duration:\s*(\d+):(\d{2}):(\d{2})\.(\d{1,3})');

  static const int _millisecondsPerSecond = 1000;
  static const int _secondsPerMinute = 60;
  static const int _minutesPerHour = 60;
  static const int _fractionDigits = 3;

  final StringBuffer _buffer = StringBuffer();

  int? _durationMs;
  bool _hasGivenUp = false;

  /// Total duration in milliseconds once enough log output has been seen,
  /// `null` until then and for inputs that never report one.
  int? get durationMs => _durationMs;

  /// Feeds one log fragment. Cheap to call for every line of a long run: it
  /// stops doing work as soon as the duration is known or clearly absent.
  void add(String fragment) {
    if (_durationMs != null || _hasGivenUp) {
      return;
    }

    _buffer.write(fragment);

    final RegExpMatch? match = _pattern.firstMatch(_buffer.toString());
    if (match == null) {
      if (_buffer.length > _maxBufferLength) {
        _hasGivenUp = true;
        _buffer.clear();
      }

      return;
    }

    _durationMs = _toMilliseconds(match);
    _buffer.clear();
  }

  static int _toMilliseconds(RegExpMatch match) {
    final int hours = int.parse(match.group(1)!);
    final int minutes = int.parse(match.group(2)!);
    final int seconds = int.parse(match.group(3)!);
    final String fraction = match.group(4)!;

    // FFmpeg prints hundredths; pad so '.4' reads as 400 ms, not 4 ms.
    final int fractionMs = int.parse(fraction.padRight(_fractionDigits, '0'));
    final int totalSeconds =
        ((hours * _minutesPerHour) + minutes) * _secondsPerMinute + seconds;

    return totalSeconds * _millisecondsPerSecond + fractionMs;
  }
}
