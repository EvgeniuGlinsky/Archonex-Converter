import 'package:flutter/foundation.dart';

import 'package:archonex_converter/project_files/features/pdf_converter/domain/models/pdf_page_size.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/domain/models/pdf_target.dart';

/// Every action the PDF converter screen can take, in one object.
///
/// Passed down instead of a dozen separate parameters, which is what keeps the
/// widget signatures readable while each widget still receives nothing but
/// functions and stays ignorant of the screen above it.
@immutable
class PdfConverterCallbacks {
  const PdfConverterCallbacks({
    required this.onPickPressed,
    required this.onClearPressed,
    required this.onRemovePressed,
    required this.onTargetSelected,
    required this.onPageSizeChanged,
    required this.onMarginChanged,
    required this.onRasterDpiChanged,
    required this.onQualityChanged,
    required this.onAdvancedToggled,
    required this.onAdvancedReset,
    required this.onCancelPressed,
    required this.onSavePressed,
    required this.onSaveAllPressed,
    required this.onUpgradePressed,
  });

  final VoidCallback onPickPressed;
  final VoidCallback onClearPressed;
  final ValueChanged<int> onRemovePressed;
  final ValueChanged<PdfTarget> onTargetSelected;
  final ValueChanged<PdfPageSize> onPageSizeChanged;
  final ValueChanged<double> onMarginChanged;
  final ValueChanged<int> onRasterDpiChanged;
  final ValueChanged<int> onQualityChanged;
  final VoidCallback onAdvancedToggled;
  final VoidCallback onAdvancedReset;
  final VoidCallback onCancelPressed;
  final ValueChanged<int> onSavePressed;
  final VoidCallback onSaveAllPressed;
  final VoidCallback onUpgradePressed;
}
