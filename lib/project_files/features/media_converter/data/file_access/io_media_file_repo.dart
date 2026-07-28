import 'package:archonex_converter/project_files/features/converter_shared/data/file_access/converter_file_picker.dart';
import 'package:archonex_converter/project_files/features/converter_shared/data/file_access/io_file_saver.dart';
import 'package:archonex_converter/project_files/features/converter_shared/domain/models/converted_file.dart';
import 'package:archonex_converter/project_files/features/converter_shared/domain/models/source_file.dart';
import 'package:archonex_converter/project_files/features/media_converter/domain/media_file_repo.dart';
import 'package:archonex_converter/project_files/features/media_converter/domain/models/media_format.dart';

/// File access on the platforms that have a real file system.
///
/// Both halves are the shared implementations; all this class decides is which
/// extensions the picker opens with.
class IoMediaFileRepo implements MediaFileRepo {
  const IoMediaFileRepo();

  static final ConverterFilePicker _picker =
      ConverterFilePicker(MediaFormat.pickableExtensions);

  static const IoFileSaver _saver = IoFileSaver();

  @override
  bool get reportsSaveLocation => true;

  @override
  Future<SourceFile?> pickSource() => _picker.pickSingle();

  @override
  Future<String?> saveConverted(ConvertedFile file) => _saver.saveOne(file);
}
