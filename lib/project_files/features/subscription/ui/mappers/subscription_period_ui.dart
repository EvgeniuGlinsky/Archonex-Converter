import 'package:flutter/widgets.dart';

import 'package:archonex_converter/l10n/app_localizations.dart';
import 'package:archonex_converter/project_files/features/subscription/domain/models/subscription_plan.dart';

/// Copy for the renewal periods. A method rather than a getter because the
/// text comes from the context, as everywhere else in the app.
extension SubscriptionPeriodUi on SubscriptionPeriod {
  String label(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return switch (this) {
      SubscriptionPeriod.monthly => l10n.paywallPeriodMonthly,
      SubscriptionPeriod.yearly => l10n.paywallPeriodYearly,
    };
  }
}
