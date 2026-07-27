import 'package:equatable/equatable.dart';

/// A file the user handed to a converter.
///
/// Deliberately holds no bytes: [sizeInBytes] is known from the picker before
/// anything is read, which is what lets the upload ceiling be enforced without
/// pulling a huge file into memory.
///
/// It also holds no format. Which formats exist is a question each converter
/// answers for itself, so callers resolve [extension] through their own format
/// enum instead.
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

  @override
  List<Object?> get props => <Object?>[name, sizeInBytes, path];
}
