import 'package:flutter/widgets.dart';

import 'package:archonex_converter/l10n/app_localizations.dart';
import 'package:archonex_converter/project_files/features/media_converter/domain/models/audio_bitrate_option.dart';

/// Copy for the audio bitrate options, kept out of the domain layer.
extension AudioBitrateOptionUi on AudioBitrateOption {
  static const String _unit = 'kbps';

  /// `Preset`, `192 kbps` …
  String label(BuildContext context) {
    final int? kbps = this.kbps;

    if (kbps == null) {
      return AppLocalizations.of(context)!.presetLabel;
    }

    return '$kbps $_unit';
  }
}
