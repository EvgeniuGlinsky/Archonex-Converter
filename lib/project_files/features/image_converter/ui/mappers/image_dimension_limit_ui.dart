import 'package:flutter/widgets.dart';

import 'package:archonex_converter/l10n/app_localizations.dart';
import 'package:archonex_converter/project_files/features/image_converter/domain/models/image_dimension_limit.dart';

/// Copy for the size cap, kept out of the domain layer.
extension ImageDimensionLimitUi on ImageDimensionLimit {
  String label(BuildContext context) {
    final int? pixels = this.pixels;
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    if (pixels != null) {
      return l10n.dimensionPixels(pixels);
    }

    return followsPreset ? l10n.dimensionAuto : l10n.dimensionOriginal;
  }
}
