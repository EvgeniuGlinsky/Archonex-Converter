import 'package:archonex/core/constants/app_file_limits.dart';

/// Turns a byte count into the short form shown next to file names.
class FileSizeFormatter {
  const FileSizeFormatter._();

  static const List<String> _units = <String>['B', 'KB', 'MB', 'GB', 'TB'];
  static const int _fractionDigits = 1;

  /// `0` → `0 B`, `1536` → `1.5 KB`, `1073741824` → `1 GB`.
  ///
  /// Bytes are never shown with decimals because a fraction of a byte is noise.
  static String format(int bytes) {
    if (bytes < AppFileLimits.bytesInKilobyte) {
      return '$bytes ${_units.first}';
    }

    double value = bytes.toDouble();
    int unitIndex = 0;

    while (value >= AppFileLimits.bytesInKilobyte &&
        unitIndex < _units.length - 1) {
      value /= AppFileLimits.bytesInKilobyte;
      unitIndex++;
    }

    return '${_trimZeros(value)} ${_units[unitIndex]}';
  }

  static String _trimZeros(double value) {
    final String text = value.toStringAsFixed(_fractionDigits);

    return text.endsWith('.0') ? text.substring(0, text.length - 2) : text;
  }
}
