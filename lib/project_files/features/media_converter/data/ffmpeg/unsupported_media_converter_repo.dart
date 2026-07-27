import 'package:archonex_converter/project_files/features/converter_shared/domain/models/conversion_failure.dart';
import 'package:archonex_converter/project_files/features/converter_shared/domain/models/converted_file.dart';
import 'package:archonex_converter/project_files/features/converter_shared/domain/models/source_file.dart';
import 'package:archonex_converter/project_files/features/media_converter/domain/media_converter_repo.dart';
import 'package:archonex_converter/project_files/features/media_converter/domain/models/conversion_job.dart';
import 'package:archonex_converter/project_files/features/media_converter/domain/models/conversion_settings.dart';
import 'package:archonex_converter/project_files/features/media_converter/domain/models/conversion_update.dart';
import 'package:archonex_converter/project_files/features/media_converter/domain/models/media_format.dart';

/// Engine for platforms FFmpeg cannot reach — the browser today.
///
/// It never pretends to convert: [isSupported] is `false`, which the screen
/// turns into an explanation, and any call that slips through fails loudly.
class UnsupportedMediaConverterRepo implements MediaConverterRepo {
  const UnsupportedMediaConverterRepo();

  @override
  bool get isSupported => false;

  @override
  ConversionJob convert({
    required SourceFile source,
    required MediaFormat target,
    required ConversionSettings settings,
  }) =>
      const _UnsupportedConversionJob();

  @override
  Future<void> discard(ConvertedFile file) async {}
}

class _UnsupportedConversionJob implements ConversionJob {
  const _UnsupportedConversionJob();

  @override
  Stream<ConversionUpdate> get updates =>
      Stream<ConversionUpdate>.error(const ConversionUnsupportedFailure());

  @override
  Future<void> cancel() async {}
}
