import 'package:archonex_converter/project_files/features/converter_shared/domain/models/converted_file.dart';
import 'package:archonex_converter/project_files/features/converter_shared/domain/models/source_file.dart';
import 'package:archonex_converter/project_files/features/image_converter/domain/models/image_conversion_job.dart';
import 'package:archonex_converter/project_files/features/image_converter/domain/models/image_conversion_settings.dart';
import 'package:archonex_converter/project_files/features/image_converter/domain/models/image_format.dart';

/// Contract for the image conversion engine.
abstract interface class ImageConverterRepo {
  /// `false` where no engine is available, so the screen can say so instead of
  /// offering a conversion that cannot run.
  bool get isSupported;

  /// Starts turning every entry of [sources] into [target].
  ///
  /// The whole batch is one job: it produces one temporary directory and one
  /// cancellation, which is what stops a stopped batch from leaking half of
  /// its output.
  ImageConversionJob convert({
    required List<SourceFile> sources,
    required ImageFormat target,
    required ImageConversionSettings settings,
  });

  /// Releases the temporary outputs behind [files]. Safe to call twice.
  Future<void> discard(List<ConvertedFile> files);
}
