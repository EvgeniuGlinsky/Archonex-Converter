import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import 'package:archonex/project_files/features/media_converter/domain/models/conversion_failure.dart';
import 'package:archonex/project_files/features/media_converter/domain/models/media_format.dart';
import 'package:archonex/project_files/features/media_converter/domain/models/source_file.dart';

/// The picking half of file access, shared by every platform variant.
///
/// Nothing here reads the source file: only its name and size are taken, which
/// is what keeps a 1 GB pick cheap. On Linux the dialog needs `zenity` or
/// `kdialog` to be installed; on macOS the user-selected read-write entitlement
/// is required (already set in `macos/Runner/*.entitlements`).
class MediaFilePicker {
  const MediaFilePicker();

  /// Opens the picker filtered to every extension the converter reads.
  ///
  /// The filter is a convenience, never validation. `FileType.custom` behaves
  /// differently on every platform: Apple platforms resolve each extension to
  /// a UTType and can reject the call outright when one has none, Android turns
  /// the list into `EXTRA_MIME_TYPES` that several document providers ignore,
  /// and the desktop dialogs all offer an "All files" escape hatch. So a filter
  /// that fails falls back to an unfiltered dialog, and whatever comes back has
  /// its extension checked by `PickSourceFileUseCase`.
  Future<SourceFile?> pickSource() async {
    FilePickerResult? result;

    try {
      result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: MediaFormat.pickableExtensions,
        // Web would otherwise eagerly read the whole file into a data URL.
        // A read stream is lazy, so the size check still happens for free.
        withData: false,
        withReadStream: kIsWeb,
      );
    } on Exception {
      result = await _pickUnfiltered();
    }

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final PlatformFile file = result.files.first;

    return SourceFile(
      name: file.name,
      sizeInBytes: file.size,
      path: kIsWeb ? null : file.path,
    );
  }

  Future<FilePickerResult?> _pickUnfiltered() async {
    try {
      return await FilePicker.pickFiles(
        type: FileType.any,
        withData: false,
        withReadStream: kIsWeb,
      );
    } on Exception {
      throw const FileReadFailure();
    }
  }
}

/// Turns a platform exception raised while saving into a domain failure.
ConversionFailure mapSaveError(Object error) {
  const String permissionMarker = 'permission';
  const List<String> storageMarkers = <String>[
    'no space',
    'not enough space',
    'disk full',
  ];

  final String message = error.toString().toLowerCase();

  if (message.contains(permissionMarker)) {
    return const SavePermissionDeniedFailure();
  }
  if (storageMarkers.any(message.contains)) {
    return const InsufficientStorageFailure();
  }

  return const SaveFailure();
}
