import 'package:flutter/material.dart';

import 'package:archonex/core/router/app_route.dart';
import 'package:archonex/l10n/app_localizations.dart';
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
        ConverterToolType.image => AppRoute.imageConverter,
        ConverterToolType.document => null,
      };

  String title(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return switch (this) {
      ConverterToolType.media => l10n.converterMediaTitle,
      ConverterToolType.image => l10n.converterImageTitle,
      ConverterToolType.document => l10n.converterDocumentTitle,
    };
  }

  String subtitle(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return switch (this) {
      ConverterToolType.media => l10n.converterMediaSubtitle,
      ConverterToolType.image => l10n.converterImageSubtitle,
      ConverterToolType.document => l10n.converterDocumentSubtitle,
    };
  }
}
