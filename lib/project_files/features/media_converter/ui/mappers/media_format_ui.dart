import 'package:flutter/material.dart';

import 'package:archonex/core/constants/app_strings.dart';
import 'package:archonex/project_files/features/media_converter/domain/models/media_format.dart';

/// Presentation details of a format group, kept out of the domain layer.
extension MediaFormatKindUi on MediaFormatKind {
  IconData get icon => switch (this) {
        MediaFormatKind.video => Icons.movie_outlined,
        MediaFormatKind.animation => Icons.gif_box_outlined,
        MediaFormatKind.audio => Icons.graphic_eq_rounded,
      };

  /// Heading above the group inside the target picker.
  String get title => switch (this) {
        MediaFormatKind.video => AppStrings.videoTargetsTitle,
        MediaFormatKind.animation => AppStrings.animationTargetsTitle,
        MediaFormatKind.audio => AppStrings.audioTargetsTitle,
      };
}
