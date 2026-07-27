import 'package:archonex_converter/project_files/features/converter_shared/domain/models/converted_file.dart';
import 'package:archonex_converter/project_files/features/converter_shared/domain/models/save_result.dart';
import 'package:archonex_converter/project_files/features/converter_shared/domain/models/source_file.dart';

/// Picking sources and writing results out, split from the engine so the two
/// can be unavailable independently.
abstract interface class PdfFileRepo {
  /// `false` where the platform starts a download instead of telling us where
  /// the file landed.
  bool get reportsSaveLocation;

  Future<List<SourceFile>> pickSources();

  /// Reads the bytes of a picked source. Needed because both directions have to
  /// look inside the file, unlike the FFmpeg converters which hand a path to a
  /// native process and never touch the contents.
  Future<List<int>> readSource(SourceFile file);

  Future<String?> saveConverted(ConvertedFile file);

  Future<SaveResult> saveAllConverted(List<ConvertedFile> files);
}
