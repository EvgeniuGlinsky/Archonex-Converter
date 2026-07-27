import 'package:equatable/equatable.dart';

/// Stable identifier of a converter offered by the File Converters category.
///
/// Adding a converter means adding a value here, an entry in the repository
/// implementation and — once it is built — a route in the UI mapper.
enum ConverterToolType { media, image, document }

/// One entry of the converter catalogue.
class ConverterTool extends Equatable {
  const ConverterTool({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.isAvailable,
  });

  final ConverterToolType type;
  final String title;
  final String subtitle;

  /// `false` while the converter is still on the roadmap. Such entries are
  /// listed, but cannot be opened.
  final bool isAvailable;

  @override
  List<Object?> get props => <Object?>[type, title, subtitle, isAvailable];
}
