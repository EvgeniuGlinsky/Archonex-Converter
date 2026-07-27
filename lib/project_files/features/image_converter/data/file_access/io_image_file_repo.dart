import 'package:archonex/project_files/features/converter_shared/data/file_access/converter_file_picker.dart';
import 'package:archonex/project_files/features/converter_shared/data/file_access/io_file_saver.dart';
import 'package:archonex/project_files/features/converter_shared/domain/models/converted_file.dart';
import 'package:archonex/project_files/features/converter_shared/domain/models/save_result.dart';
import 'package:archonex/project_files/features/converter_shared/domain/models/source_file.dart';
import 'package:archonex/project_files/features/image_converter/domain/image_file_repo.dart';
import 'package:archonex/project_files/features/image_converter/domain/models/image_format.dart';

/// File access on the platforms that have a real file system.
class IoImageFileRepo implements ImageFileRepo {
  const IoImageFileRepo();

  static final ConverterFilePicker _picker =
      ConverterFilePicker(ImageFormat.pickableExtensions);

  static const IoFileSaver _saver = IoFileSaver();

  @override
  bool get reportsSaveLocation => true;

  @override
  Future<List<SourceFile>> pickSources() => _picker.pickMultiple();

  @override
  Future<String?> saveConverted(ConvertedFile file) => _saver.saveOne(file);

  @override
  Future<SaveResult> saveAllConverted(List<ConvertedFile> files) =>
      _saver.saveAll(files);
}
