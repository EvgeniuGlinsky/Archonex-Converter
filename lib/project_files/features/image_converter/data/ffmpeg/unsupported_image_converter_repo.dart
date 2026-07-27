import 'package:archonex/project_files/features/converter_shared/domain/models/conversion_failure.dart';
import 'package:archonex/project_files/features/converter_shared/domain/models/converted_file.dart';
import 'package:archonex/project_files/features/converter_shared/domain/models/source_file.dart';
import 'package:archonex/project_files/features/image_converter/domain/image_converter_repo.dart';
import 'package:archonex/project_files/features/image_converter/domain/models/image_conversion_job.dart';
import 'package:archonex/project_files/features/image_converter/domain/models/image_conversion_settings.dart';
import 'package:archonex/project_files/features/image_converter/domain/models/image_conversion_update.dart';
import 'package:archonex/project_files/features/image_converter/domain/models/image_format.dart';

/// Engine for platforms FFmpeg cannot reach — the browser today.
///
/// It never pretends to convert: [isSupported] is `false`, which the screen
/// turns into an explanation, and any call that slips through fails loudly.
class UnsupportedImageConverterRepo implements ImageConverterRepo {
  const UnsupportedImageConverterRepo();

  @override
  bool get isSupported => false;

  @override
  ImageConversionJob convert({
    required List<SourceFile> sources,
    required ImageFormat target,
    required ImageConversionSettings settings,
  }) =>
      const _UnsupportedImageConversionJob();

  @override
  Future<void> discard(List<ConvertedFile> files) async {}
}

class _UnsupportedImageConversionJob implements ImageConversionJob {
  const _UnsupportedImageConversionJob();

  @override
  Stream<ImageConversionUpdate> get updates =>
      Stream<ImageConversionUpdate>.error(const ConversionUnsupportedFailure());

  @override
  Future<void> cancel() async {}
}
