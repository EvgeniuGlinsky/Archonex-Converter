import 'dart:io';

import 'package:archonex_converter/project_files/features/converter_shared/data/file_access/converter_file_picker.dart';
import 'package:archonex_converter/project_files/features/converter_shared/data/file_access/io_file_saver.dart';
import 'package:archonex_converter/project_files/features/converter_shared/domain/models/conversion_failure.dart';
import 'package:archonex_converter/project_files/features/converter_shared/domain/models/converted_file.dart';
import 'package:archonex_converter/project_files/features/converter_shared/domain/models/save_result.dart';
import 'package:archonex_converter/project_files/features/converter_shared/domain/models/source_file.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/domain/models/pdf_format.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/domain/pdf_file_repo.dart';

/// File access on the platforms that have a real file system.
class IoPdfFileRepo implements PdfFileRepo {
  const IoPdfFileRepo();

  static final ConverterFilePicker _picker =
      ConverterFilePicker(PdfFormat.pickableExtensions);

  static const IoFileSaver _saver = IoFileSaver();

  @override
  bool get reportsSaveLocation => true;

  @override
  Future<List<SourceFile>> pickSources() => _picker.pickMultiple();

  @override
  Future<List<int>> readSource(SourceFile file) async {
    final String? path = file.path;
    if (path == null) {
      throw const FileReadFailure();
    }

    try {
      return await File(path).readAsBytes();
    } on FileSystemException {
      throw const FileReadFailure();
    }
  }

  @override
  Future<String?> saveConverted(ConvertedFile file) => _saver.saveOne(file);

  @override
  Future<SaveResult> saveAllConverted(List<ConvertedFile> files) =>
      _saver.saveAll(files);
}
