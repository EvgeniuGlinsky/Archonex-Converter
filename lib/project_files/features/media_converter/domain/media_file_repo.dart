import 'package:archonex/project_files/features/media_converter/domain/models/converted_file.dart';
import 'package:archonex/project_files/features/media_converter/domain/models/source_file.dart';

/// Contract for getting files in from and out to the platform.
abstract interface class MediaFileRepo {
  /// Opens the system picker filtered to every format the converter reads.
  ///
  /// Returns `null` when the user closes the dialog without choosing anything.
  /// Throws `FileReadFailure` when the platform hands back something unusable.
  Future<SourceFile?> pickSource();

  /// Opens the system save dialog, or starts a browser download on web.
  ///
  /// Returns where the file landed, `null` when the user cancelled or when the
  /// platform does not report a location (the browser). Throws
  /// `SavePermissionDeniedFailure`, `InsufficientStorageFailure` or
  /// `SaveFailure`.
  Future<String?> saveConverted(ConvertedFile file);

  /// `true` when the platform never reports a save location, so a `null` from
  /// [saveConverted] means success rather than a cancelled dialog.
  bool get reportsSaveLocation;
}
