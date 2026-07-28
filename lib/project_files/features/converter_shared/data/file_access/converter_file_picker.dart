import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import 'package:archonex_converter/project_files/features/converter_shared/domain/models/conversion_failure.dart';
import 'package:archonex_converter/project_files/features/converter_shared/domain/models/source_file.dart';

/// The picking half of file access, shared by every converter and platform.
///
/// Nothing here reads the source file: only its name and size are taken, which
/// is what keeps a large pick cheap. On Linux the dialog needs `zenity` or
/// `kdialog` to be installed; on macOS the user-selected read-write entitlement
/// is required (already set in `macos/Runner/*.entitlements`).
class ConverterFilePicker {
  const ConverterFilePicker(this.allowedExtensions);

  /// Every extension the calling converter reads, aliases included.
  final List<String> allowedExtensions;

  /// Opens the picker for a single file.
  Future<SourceFile?> pickSingle() async {
    final FilePickerResult? result = await _pick(allowsMultiple: false);
    if (result == null || result.files.isEmpty) {
      return null;
    }

    return _toSourceFile(result.files.first);
  }

  /// Opens the picker for any number of files.
  ///
  /// Returns an empty list when the user closed the dialog without choosing.
  Future<List<SourceFile>> pickMultiple() async {
    final FilePickerResult? result = await _pick(allowsMultiple: true);
    if (result == null) {
      return const <SourceFile>[];
    }

    return result.files.map(_toSourceFile).toList(growable: false);
  }

  /// The filter is a convenience, never validation. `FileType.custom` behaves
  /// differently on every platform: Apple platforms resolve each extension to
  /// a UTType and can reject the call outright when one has none, Android turns
  /// the list into `EXTRA_MIME_TYPES` that several document providers ignore,
  /// and the desktop dialogs all offer an "All files" escape hatch. So a filter
  /// that fails falls back to an unfiltered dialog, and whatever comes back has
  /// its extension checked by the calling use case.
  Future<FilePickerResult?> _pick({required bool allowsMultiple}) async {
    try {
      return await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowedExtensions,
        allowMultiple: allowsMultiple,
        // Web would otherwise eagerly read the whole file into a data URL.
        // A read stream is lazy, so the size check still happens for free.
        withData: false,
        withReadStream: kIsWeb,
      );
    } on Exception {
      return _pickUnfiltered(allowsMultiple: allowsMultiple);
    }
  }

  Future<FilePickerResult?> _pickUnfiltered({
    required bool allowsMultiple,
  }) async {
    try {
      return await FilePicker.pickFiles(
        type: FileType.any,
        allowMultiple: allowsMultiple,
        withData: false,
        withReadStream: kIsWeb,
      );
    } on Exception {
      throw const FileReadFailure();
    }
  }

  SourceFile _toSourceFile(PlatformFile file) => SourceFile(
        name: file.name,
        sizeInBytes: file.size,
        path: kIsWeb ? null : file.path,
      );
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
