import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import 'package:archonex/project_files/features/converter_shared/data/file_access/converter_file_picker.dart';
import 'package:archonex/project_files/features/converter_shared/domain/models/conversion_failure.dart';
import 'package:archonex/project_files/features/converter_shared/domain/models/converted_file.dart';
import 'package:archonex/project_files/features/converter_shared/domain/models/save_result.dart';

/// Writing results out on the platforms that have a real file system.
///
/// Saving takes two different routes, because `file_picker` behaves
/// differently per platform (verified against file_picker 11.0.2):
///
/// * Desktop — `saveFile` without `bytes` returns the chosen destination and
///   writes nothing, so the temp output is copied across by the OS. Memory use
///   stays flat no matter how big the result is.
/// * Android and iOS — `saveFile` throws without `bytes`, so the output has to
///   be read into memory first. This is the one place where the size of a
///   conversion result still matters.
class IoFileSaver {
  const IoFileSaver();

  /// Appended before the extension when a name is already taken in the chosen
  /// folder, e.g. `photo (2).webp`.
  static const int _firstSuffix = 2;
  static const int _maxSuffix = 1000;

  /// One file through the system save dialog. `null` when the user cancelled.
  Future<String?> saveOne(ConvertedFile file) async {
    final bool needsBytes = Platform.isAndroid || Platform.isIOS;

    try {
      final Uint8List? bytes =
          needsBytes ? await File(file.path).readAsBytes() : null;

      final String? destination = await FilePicker.saveFile(
        fileName: file.name,
        bytes: bytes,
      );

      if (destination == null) {
        return null;
      }

      if (!needsBytes) {
        await File(file.path).copy(destination);
      }

      return destination;
    } on OutOfMemoryError {
      // Not an Exception, so `on Exception` below would let it escape the repo,
      // the use case and the bloc alike — leaving the screen stuck on "Saving…"
      // forever. This is the expected failure for a large result on a phone:
      // the whole file has to be resident to hand it to the platform.
      throw const ResultTooLargeToSaveFailure();
    } on Exception catch (error) {
      throw mapSaveError(error);
    }
  }

  /// Every result at once, into a single folder the user picks one time.
  ///
  /// Asking for a destination per file would mean thirty dialogs for thirty
  /// photos. The folder route is not universally available though — Android
  /// can hand back a storage-access URI that `dart:io` cannot write to — so a
  /// folder that turns out to be unusable silently degrades to one dialog per
  /// file rather than failing the save.
  Future<SaveResult> saveAll(List<ConvertedFile> files) async {
    if (files.isEmpty) {
      return const SaveResult.cancelled();
    }

    final String? directory = await _pickDirectory();

    if (directory != null) {
      final int written = await _copyAllInto(directory, files);

      if (written == files.length) {
        return SaveResult(
          outcome: SaveOutcome.savedToLocation,
          location: directory,
          savedCount: written,
        );
      }
    }

    return _saveOneByOne(files);
  }

  /// The chosen folder, or `null` when the user cancelled or the platform has
  /// no folder picker to offer. Both cases lead to the same fallback.
  Future<String?> _pickDirectory() async {
    try {
      return await FilePicker.getDirectoryPath();
    } on Exception {
      return null;
    }
  }

  /// Copies everything into [directory], returning how many landed.
  ///
  /// A partial result is treated as a failed folder save by the caller: it is
  /// better to ask again per file than to leave the user guessing which half
  /// of the batch made it.
  Future<int> _copyAllInto(
    String directory,
    List<ConvertedFile> files,
  ) async {
    int written = 0;

    for (final ConvertedFile file in files) {
      try {
        final String destination = await _freePathIn(directory, file.name);
        await File(file.path).copy(destination);
        written++;
      } on Exception {
        return written;
      }
    }

    return written;
  }

  /// A path inside [directory] that nothing occupies yet.
  ///
  /// Two sources named `holiday.png` and `holiday.jpg` both become
  /// `holiday.webp`, so without this the second one would overwrite the first.
  Future<String> _freePathIn(String directory, String name) async {
    final String separator = Platform.pathSeparator;
    final int dotIndex = name.lastIndexOf('.');
    final String base = dotIndex == -1 ? name : name.substring(0, dotIndex);
    final String extension = dotIndex == -1 ? '' : name.substring(dotIndex);

    String candidate = '$directory$separator$name';

    for (int suffix = _firstSuffix;
        await File(candidate).exists() && suffix < _maxSuffix;
        suffix++) {
      candidate = '$directory$separator$base ($suffix)$extension';
    }

    return candidate;
  }

  /// One dialog per file, stopping as soon as the user closes one.
  Future<SaveResult> _saveOneByOne(List<ConvertedFile> files) async {
    int saved = 0;
    String? lastLocation;

    for (final ConvertedFile file in files) {
      final String? location = await saveOne(file);

      if (location == null) {
        break;
      }

      saved++;
      lastLocation = location;
    }

    if (saved == 0 || lastLocation == null) {
      return const SaveResult.cancelled();
    }

    return SaveResult(
      outcome: SaveOutcome.savedToLocation,
      location: File(lastLocation).parent.path,
      savedCount: saved,
    );
  }
}
