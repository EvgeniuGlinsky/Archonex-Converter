import 'package:flutter/material.dart';

import 'package:archonex_converter/l10n/app_localizations.dart';
import 'package:archonex_converter/project_files/features/usage_quota/domain/models/conversion_allowance.dart';

/// Turns an allowance into the line the converter screens show.
///
/// The reset date is formatted by `MaterialLocalizations`, so it reads the way
/// the chosen language writes dates rather than the way this file would.
extension ConversionAllowanceUi on ConversionAllowance {
  String message(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final DateTime? reset = resetsAt;

    if (!isExhausted || reset == null) {
      return l10n.quotaRemaining(remaining);
    }

    return l10n.quotaExhaustedNotice(
      limit,
      MaterialLocalizations.of(context).formatMediumDate(reset),
    );
  }

  IconData get icon =>
      isExhausted ? Icons.lock_outline_rounded : Icons.bolt_outlined;
}
