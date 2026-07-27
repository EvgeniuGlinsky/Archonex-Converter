import 'package:archonex/project_files/features/media_converter/domain/models/conversion_job.dart';
import 'package:archonex/project_files/features/media_converter/domain/models/conversion_settings.dart';
import 'package:archonex/project_files/features/media_converter/domain/models/converted_file.dart';
import 'package:archonex/project_files/features/media_converter/domain/models/media_format.dart';
import 'package:archonex/project_files/features/media_converter/domain/models/source_file.dart';

/// Contract for the conversion engine.
abstract interface class MediaConverterRepo {
  /// `false` where no engine is available, so the screen can say so instead of
  /// offering a conversion that cannot run.
  bool get isSupported;

  /// Starts turning [source] into [target] and returns a handle to the job.
  ConversionJob convert({
    required SourceFile source,
    required MediaFormat target,
    required ConversionSettings settings,
  });

  /// Releases the temporary output behind [file]. Safe to call twice.
  Future<void> discard(ConvertedFile file);
}
