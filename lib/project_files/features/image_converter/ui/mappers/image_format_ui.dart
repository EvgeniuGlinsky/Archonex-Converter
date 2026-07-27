import 'package:flutter/material.dart';

import 'package:archonex/project_files/features/converter_shared/ui/widgets/format_badge.dart';
import 'package:archonex/project_files/features/image_converter/domain/models/image_format.dart';

/// Presentation details of an image format, kept out of the domain layer.
extension ImageFormatUi on ImageFormat {
  IconData get icon => switch (this) {
        ImageFormat.gif => Icons.gif_box_outlined,
        ImageFormat.png ||
        ImageFormat.tiff ||
        ImageFormat.tga ||
        ImageFormat.bmp =>
          Icons.photo_size_select_actual_outlined,
        ImageFormat.jpg ||
        ImageFormat.webp ||
        ImageFormat.heic ||
        ImageFormat.avif ||
        ImageFormat.ico =>
          Icons.photo_outlined,
      };

  /// Colour the format pill borrows, so lossless and lossy stay tellable apart
  /// at a glance.
  FormatBadgeTone get badgeTone {
    if (this == ImageFormat.gif) {
      return FormatBadgeTone.secondary;
    }

    return isLossless ? FormatBadgeTone.tertiary : FormatBadgeTone.primary;
  }
}
