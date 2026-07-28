import 'package:flutter/widgets.dart';

import 'package:archonex_converter/l10n/app_localizations.dart';
import 'package:archonex_converter/project_files/features/subscription/domain/models/purchase_outcome.dart';

/// What to tell the user after an attempt to pay, redeem or restore.
///
/// Exhaustive on the enum, so a new outcome cannot be added without deciding
/// what it says.
extension PurchaseOutcomeUi on PurchaseOutcome {
  String message(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return switch (this) {
      PurchaseOutcome.succeeded => l10n.purchaseSucceeded,
      PurchaseOutcome.cancelled => l10n.purchaseCancelled,
      PurchaseOutcome.nothingToRestore => l10n.purchaseNothingToRestore,
      PurchaseOutcome.invalidLicenseKey => l10n.purchaseInvalidLicenseKey,
      PurchaseOutcome.unavailable => l10n.purchaseUnavailable,
      PurchaseOutcome.failed => l10n.purchaseFailed,
    };
  }
}
