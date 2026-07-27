import 'package:flutter/widgets.dart';

import 'package:archonex/l10n/app_localizations.dart';
import 'package:archonex/project_files/features/image_converter/domain/models/image_quality.dart';

/// Copy for the image quality presets, kept out of the domain layer.
extension ImageQualityUi on ImageQuality {
  String label(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return switch (this) {
      ImageQuality.high => l10n.qualityHigh,
      ImageQuality.balanced => l10n.qualityBalanced,
      ImageQuality.compact => l10n.qualityCompact,
    };
  }

  /// One line under the selector saying what the choice costs.
  String hint(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return switch (this) {
      ImageQuality.high => l10n.imageQualityHighHint,
      ImageQuality.balanced => l10n.imageQualityBalancedHint,
      ImageQuality.compact => l10n.imageQualityCompactHint,
    };
  }
}
