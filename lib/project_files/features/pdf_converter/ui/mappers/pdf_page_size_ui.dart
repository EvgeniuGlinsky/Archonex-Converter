import 'package:flutter/material.dart';

import 'package:archonex_converter/l10n/app_localizations.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/domain/models/pdf_page_size.dart';

/// Copy for the page size choice. A method rather than a getter because the
/// label is localized and needs a context — see the project's l10n rule.
extension PdfPageSizeUi on PdfPageSize {
  String label(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return switch (this) {
      PdfPageSize.fitSource => l10n.pageSizeFitSource,
      PdfPageSize.a4 => l10n.pageSizeA4,
      PdfPageSize.letter => l10n.pageSizeLetter,
    };
  }
}

/// The three margins offered, in points.
///
/// A dropdown of named steps rather than a free number: nobody wants to type a
/// margin in 1/72 inch, and the three that matter are none, some, and generous.
enum PdfMarginOption {
  none(points: 0),
  small(points: 24),
  large(points: 56);

  const PdfMarginOption({required this.points});

  final double points;

  String label(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return switch (this) {
      PdfMarginOption.none => l10n.marginNone,
      PdfMarginOption.small => l10n.marginSmall,
      PdfMarginOption.large => l10n.marginLarge,
    };
  }

  /// The option [points] belongs to, falling back to the middle one so a value
  /// that came from somewhere else still shows something sensible.
  static PdfMarginOption fromPoints(double points) => PdfMarginOption.values
      .firstWhere(
        (option) => option.points == points,
        orElse: () => PdfMarginOption.small,
      );
}
