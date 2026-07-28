import 'package:archonex_converter/project_files/features/converter_shared/domain/models/converted_file.dart';

/// One tick of a running conversion.
sealed class ConversionUpdate {
  const ConversionUpdate();
}

/// How far the conversion got.
final class ConversionProgress extends ConversionUpdate {
  const ConversionProgress(this.value);

  /// Fraction between `0` and `1`, or `null` when the total length of the
  /// input is unknown — GIFs frequently report no duration. `null` renders as
  /// an indeterminate progress bar.
  final double? value;
}

/// The conversion finished and produced [file].
final class ConversionCompleted extends ConversionUpdate {
  const ConversionCompleted(this.file);

  final ConvertedFile file;
}
