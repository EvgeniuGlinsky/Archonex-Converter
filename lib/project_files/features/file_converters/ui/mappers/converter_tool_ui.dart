import 'package:flutter/material.dart';

import 'package:archonex/core/router/app_route.dart';
import 'package:archonex/project_files/features/file_converters/domain/models/converter_tool.dart';

/// Presentation details of a converter, kept out of the domain layer.
extension ConverterToolTypeUi on ConverterToolType {
  IconData get icon => switch (this) {
        ConverterToolType.media => Icons.movie_filter_outlined,
        ConverterToolType.image => Icons.image_outlined,
        ConverterToolType.document => Icons.description_outlined,
      };

  /// Destination of the converter, or `null` while it is not built yet.
  AppRoute? get route => switch (this) {
        ConverterToolType.media => AppRoute.mediaConverter,
        ConverterToolType.image => null,
        ConverterToolType.document => null,
      };
}
