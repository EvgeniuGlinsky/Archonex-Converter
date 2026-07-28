import 'package:archonex_converter/project_files/features/converter_shared/domain/models/conversion_failure.dart';
import 'package:archonex_converter/project_files/features/converter_shared/domain/models/converted_file.dart';

/// One step of a running batch.
///
/// Photos carry no duration, so there is no fraction to report from inside a
/// single conversion the way a video reports one. Progress is therefore the
/// batch itself: which item started, which finished, and how. That is an exact
/// measure rather than an estimate.
sealed class ImageConversionUpdate {
  const ImageConversionUpdate();

  /// Position of the photo this update is about, in the order it was handed to
  /// the engine.
  int get index;
}

/// Work began on the photo at [index].
final class ImageItemStarted extends ImageConversionUpdate {
  const ImageItemStarted(this.index);

  @override
  final int index;
}

/// The photo at [index] was written to [file].
final class ImageItemConverted extends ImageConversionUpdate {
  const ImageItemConverted(this.index, this.file);

  @override
  final int index;

  final ConvertedFile file;
}

/// The photo at [index] could not be converted; the batch carries on.
final class ImageItemFailed extends ImageConversionUpdate {
  const ImageItemFailed(this.index, this.failure);

  @override
  final int index;

  final ConversionFailure failure;
}
