import 'package:archonex/project_files/features/converter_shared/domain/models/conversion_failure.dart';
import 'package:archonex/project_files/features/converter_shared/domain/models/converted_file.dart';
import 'package:archonex/project_files/features/converter_shared/domain/models/save_result.dart';
import 'package:archonex/project_files/features/converter_shared/domain/models/source_file.dart';
import 'package:archonex/project_files/features/image_converter/domain/image_file_repo.dart';

/// File access where no conversion engine exists.
///
/// Picking photos the app cannot convert would be a dead end, so every half
/// reports the platform as unsupported instead.
class UnsupportedImageFileRepo implements ImageFileRepo {
  const UnsupportedImageFileRepo();

  @override
  bool get reportsSaveLocation => false;

  @override
  Future<List<SourceFile>> pickSources() async =>
      throw const ConversionUnsupportedFailure();

  @override
  Future<String?> saveConverted(ConvertedFile file) async =>
      throw const ConversionUnsupportedFailure();

  @override
  Future<SaveResult> saveAllConverted(List<ConvertedFile> files) async =>
      throw const ConversionUnsupportedFailure();
}
