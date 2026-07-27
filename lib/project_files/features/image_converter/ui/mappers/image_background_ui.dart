import 'package:flutter/widgets.dart';

import 'package:archonex/l10n/app_localizations.dart';
import 'package:archonex/project_files/features/image_converter/domain/models/image_background.dart';

/// Copy for the transparency backdrop, kept out of the domain layer.
extension ImageBackgroundUi on ImageBackground {
  String label(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return switch (this) {
      ImageBackground.white => l10n.backgroundWhite,
      ImageBackground.black => l10n.backgroundBlack,
    };
  }
}
