import 'package:equatable/equatable.dart';

/// The result of a conversion, sitting in a temporary file.
///
/// Deliberately holds a path rather than bytes: the engine writes megabytes (or
/// more) to disk, and the save step streams from here to the chosen
/// destination instead of routing everything through memory.
///
/// The file is owned by the converter repository — call `discard` on it once
/// the result is no longer needed.
class ConvertedFile extends Equatable {
  const ConvertedFile({
    required this.name,
    required this.path,
    required this.sizeInBytes,
  });

  /// File name including the target extension, as offered in the save dialog.
  final String name;

  /// Absolute path of the temporary output file.
  final String path;

  final int sizeInBytes;

  @override
  List<Object?> get props => <Object?>[name, path, sizeInBytes];
}
