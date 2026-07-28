import 'package:flutter/material.dart';

import 'package:archonex_converter/core/constants/app_radius.dart';
import 'package:archonex_converter/core/constants/app_spacing.dart';
import 'package:archonex_converter/l10n/app_localizations.dart';
import 'package:archonex_converter/project_files/features/usage_quota/domain/models/conversion_allowance.dart';
import 'package:archonex_converter/project_files/features/usage_quota/ui/mappers/conversion_allowance_ui.dart';

/// States how much of the free monthly count is left, and offers the way out
/// of it.
///
/// Always on screen for a free device, before anything is even picked — for
/// the same reason `FileSizeLimitNotice` is: a limit discovered only once the
/// work is set up reads as a bug rather than as a plan.
///
/// A subscribed device sees nothing at all. There is no count to report, and a
/// banner congratulating someone for paying is just clutter.
class QuotaNotice extends StatelessWidget {
  const QuotaNotice({
    required this.allowance,
    required this.onUpgradePressed,
    super.key,
  });

  static const double _iconSize = 18;
  static const double _padding = AppSpacing.md;

  final ConversionAllowance allowance;
  final VoidCallback onUpgradePressed;

  @override
  Widget build(BuildContext context) {
    if (allowance.isUnlimited) {
      return const SizedBox.shrink();
    }

    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final bool isExhausted = allowance.isExhausted;

    final Color foreground =
        isExhausted ? colors.onSurface : colors.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.all(_padding),
      decoration: BoxDecoration(
        // Only the exhausted state earns a filled background: until then this
        // is a status line, not a demand.
        color: isExhausted ? colors.surfaceContainerHighest : null,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: <Widget>[
          Icon(allowance.icon, size: _iconSize, color: foreground),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              allowance.message(context),
              style: theme.textTheme.bodyMedium?.copyWith(color: foreground),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          TextButton(
            onPressed: onUpgradePressed,
            child: Text(AppLocalizations.of(context)!.quotaUpgradeLabel),
          ),
        ],
      ),
    );
  }
}
