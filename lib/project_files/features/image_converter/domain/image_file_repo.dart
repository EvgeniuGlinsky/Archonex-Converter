import 'package:archonex/project_files/features/converter_shared/domain/models/converted_file.dart';
import 'package:archonex/project_files/features/converter_shared/domain/models/save_result.dart';
import 'package:archonex/project_files/features/converter_shared/domain/models/source_file.dart';

/// Contract for getting photos in from and out to the platform.
abstract interface class ImageFileRepo {
  /// Opens the system picker, filtered to every format the converter reads and
  /// allowing more than one choice.
  ///
  /// Returns an empty list when the user closes the dialog without choosing.
  /// Throws `FileReadFailure` when the platform hands back something unusable.
  Future<List<SourceFile>> pickSources();

  /// Opens the system save dialog for one result.
  ///
  /// Returns where the file landed, `null` when the user cancelled or when the
  /// platform does not report a location.
  Future<String?> saveConverted(ConvertedFile file);

  /// Writes every result out, asking for a destination as few times as the
  /// platform allows.
  Future<SaveResult> saveAllConverted(List<ConvertedFile> files);

  /// `true` when the platform never reports a save location, so a `null` from
  /// [saveConverted] means success rather than a cancelled dialog.
  bool get reportsSaveLocation;
}
