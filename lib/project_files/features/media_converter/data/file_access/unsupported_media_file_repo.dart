import 'package:archonex/project_files/features/media_converter/domain/media_file_repo.dart';
import 'package:archonex/project_files/features/media_converter/domain/models/conversion_failure.dart';
import 'package:archonex/project_files/features/media_converter/domain/models/converted_file.dart';
import 'package:archonex/project_files/features/media_converter/domain/models/source_file.dart';

/// File access where no conversion engine exists.
///
/// Picking a file the app cannot convert would be a dead end, so both halves
/// report the platform as unsupported instead.
class UnsupportedMediaFileRepo implements MediaFileRepo {
  const UnsupportedMediaFileRepo();

  @override
  bool get reportsSaveLocation => false;

  @override
  Future<SourceFile?> pickSource() async =>
      throw const ConversionUnsupportedFailure();

  @override
  Future<String?> saveConverted(ConvertedFile file) async =>
      throw const ConversionUnsupportedFailure();
}
