import 'package:flutter/foundation.dart';

import 'package:archonex_converter/project_files/features/image_converter/domain/models/image_background.dart';
import 'package:archonex_converter/project_files/features/image_converter/domain/models/image_dimension_limit.dart';
import 'package:archonex_converter/project_files/features/image_converter/domain/models/image_format.dart';
import 'package:archonex_converter/project_files/features/image_converter/domain/models/image_quality.dart';

/// Everything the image converter screen can be asked to do, in one bundle.
///
/// Threading fourteen actions through the body as fourteen separate parameters
/// would make every widget signature unreadable and every call site a wall of
/// arguments. Grouping them keeps the widgets free of any dependency on their
/// parent — they still only receive functions.
@immutable
class ImageConverterCallbacks {
  const ImageConverterCallbacks({
    required this.onPickPressed,
    required this.onClearPressed,
    required this.onRemovePressed,
    required this.onTargetSelected,
    required this.onQualityChanged,
    required this.onAdvancedToggled,
    required this.onDimensionChanged,
    required this.onImageQualityChanged,
    required this.onBackgroundChanged,
    required this.onKeepMetadataChanged,
    required this.onAdvancedReset,
    required this.onCancelPressed,
    required this.onSavePressed,
    required this.onSaveAllPressed,
  });

  final VoidCallback onPickPressed;
  final VoidCallback onClearPressed;
  final ValueChanged<int> onRemovePressed;
  final ValueChanged<ImageFormat> onTargetSelected;
  final ValueChanged<ImageQuality> onQualityChanged;
  final VoidCallback onAdvancedToggled;
  final ValueChanged<ImageDimensionLimit> onDimensionChanged;
  final ValueChanged<int> onImageQualityChanged;
  final ValueChanged<ImageBackground> onBackgroundChanged;
  final ValueChanged<bool> onKeepMetadataChanged;
  final VoidCallback onAdvancedReset;
  final VoidCallback onCancelPressed;
  final ValueChanged<int> onSavePressed;
  final VoidCallback onSaveAllPressed;
}
