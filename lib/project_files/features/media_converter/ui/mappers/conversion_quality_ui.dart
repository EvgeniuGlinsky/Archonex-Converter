import 'package:flutter/widgets.dart';

import 'package:archonex/l10n/app_localizations.dart';
import 'package:archonex/project_files/features/media_converter/domain/models/conversion_quality.dart';

/// Copy for the quality presets, kept out of the domain layer.
extension ConversionQualityUi on ConversionQuality {
  String label(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return switch (this) {
      ConversionQuality.high => l10n.qualityHigh,
      ConversionQuality.balanced => l10n.qualityBalanced,
      ConversionQuality.compact => l10n.qualityCompact,
    };
  }

  /// One line under the selector saying what the choice costs.
  String hint(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return switch (this) {
      ConversionQuality.high => l10n.qualityHighHint,
      ConversionQuality.balanced => l10n.qualityBalancedHint,
      ConversionQuality.compact => l10n.qualityCompactHint,
    };
  }
}
