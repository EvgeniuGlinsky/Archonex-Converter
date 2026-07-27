import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import 'package:archonex/project_files/features/media_converter/data/file_access/media_file_picker.dart';
import 'package:archonex/project_files/features/media_converter/domain/media_file_repo.dart';
import 'package:archonex/project_files/features/media_converter/domain/models/conversion_failure.dart';
import 'package:archonex/project_files/features/media_converter/domain/models/converted_file.dart';
import 'package:archonex/project_files/features/media_converter/domain/models/source_file.dart';

/// File access on the platforms that have a real file system.
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
class IoMediaFileRepo implements MediaFileRepo {
  const IoMediaFileRepo();

  static const MediaFilePicker _picker = MediaFilePicker();

  @override
  bool get reportsSaveLocation => true;

  @override
  Future<SourceFile?> pickSource() => _picker.pickSource();

  @override
  Future<String?> saveConverted(ConvertedFile file) async {
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
}
