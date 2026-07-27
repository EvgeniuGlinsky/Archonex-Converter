import 'package:equatable/equatable.dart';

import 'package:archonex/project_files/features/media_converter/domain/models/media_format.dart';

/// A file the user handed to the converter.
///
/// Deliberately holds no bytes: [sizeInBytes] is known from the picker before
/// anything is read, which is what lets the 1 GB limit be enforced without
/// pulling a huge file into memory.
class SourceFile extends Equatable {
  const SourceFile({
    required this.name,
    required this.sizeInBytes,
    this.path,
  });

  /// File name including its extension.
  final String name;

  final int sizeInBytes;

  /// Absolute path on the native platforms. Always `null` on web, where a real
  /// conversion engine will have to read through a stream instead.
  final String? path;

  /// Lower case extension without the leading dot, or an empty string.
  String get extension {
    final int dotIndex = name.lastIndexOf('.');

    return dotIndex == -1 ? '' : name.substring(dotIndex + 1).toLowerCase();
  }

  /// File name without its extension.
  String get baseName {
    final int dotIndex = name.lastIndexOf('.');

    return dotIndex == -1 ? name : name.substring(0, dotIndex);
  }

  /// The format behind [extension], or `null` when it is not supported.
  MediaFormat? get format => MediaFormat.fromExtension(extension);

  @override
  List<Object?> get props => <Object?>[name, sizeInBytes, path];
}
