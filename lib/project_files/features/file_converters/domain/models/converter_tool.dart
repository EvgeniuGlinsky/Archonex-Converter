import 'package:equatable/equatable.dart';

/// Stable identifier of a converter offered by the File Converters category.
///
/// Adding a converter means adding a value here, an entry in the repository
/// implementation and — once it is built — a route in the UI mapper.
enum ConverterToolType { media, image, pdf }

/// One entry of the converter catalogue.
///
/// Carries only the stable identity — its title and subtitle are localized
/// copy resolved in the UI layer, see `ConverterToolTypeUi`.
class ConverterTool extends Equatable {
  const ConverterTool({required this.type, required this.isAvailable});

  final ConverterToolType type;

  /// `false` while the converter is still on the roadmap. Such entries are
  /// listed, but cannot be opened.
  final bool isAvailable;

  @override
  List<Object?> get props => <Object?>[type, isAvailable];
}
