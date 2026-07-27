import 'package:flutter/widgets.dart';

import 'package:archonex/l10n/app_localizations.dart';
import 'package:archonex/project_files/features/media_converter/domain/models/frame_rate_option.dart';

/// Copy for the frame rate options, kept out of the domain layer.
extension FrameRateOptionUi on FrameRateOption {
  static const String _unit = 'fps';

  /// `Auto`, `Original`, `30 fps` …
  String label(BuildContext context) {
    final int? fps = this.fps;

    if (fps != null) {
      return '$fps $_unit';
    }

    final AppLocalizations l10n = AppLocalizations.of(context)!;
    return followsPreset ? l10n.autoLabel : l10n.originalLabel;
  }
}
