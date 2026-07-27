import 'package:flutter/material.dart';

import 'package:archonex_converter/project_files/features/pdf_converter/domain/models/pdf_target.dart';

/// Presentation details of an output format, kept out of the domain layer.
extension PdfTargetUi on PdfTarget {
  IconData get icon => switch (this) {
        PdfTarget.pdf => Icons.picture_as_pdf_outlined,
        PdfTarget.png => Icons.image_outlined,
        PdfTarget.jpg => Icons.photo_outlined,
      };
}
