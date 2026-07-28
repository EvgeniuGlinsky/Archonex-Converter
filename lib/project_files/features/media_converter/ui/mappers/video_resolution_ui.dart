import 'package:flutter/widgets.dart';

import 'package:archonex_converter/l10n/app_localizations.dart';
import 'package:archonex_converter/project_files/features/media_converter/domain/models/video_resolution.dart';

/// Copy for the resolution options, kept out of the domain layer.
extension VideoResolutionUi on VideoResolution {
  /// `Auto`, `Original`, `1080p` …
  String label(BuildContext context) {
    final int? height = this.height;

    if (height != null) {
      return '${height}p';
    }

    final AppLocalizations l10n = AppLocalizations.of(context)!;
    return followsPreset ? l10n.autoLabel : l10n.originalLabel;
  }
}
