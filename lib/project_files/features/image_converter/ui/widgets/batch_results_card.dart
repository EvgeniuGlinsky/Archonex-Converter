import 'package:flutter/material.dart';

import 'package:archonex_converter/core/constants/app_radius.dart';
import 'package:archonex_converter/core/constants/app_spacing.dart';
import 'package:archonex_converter/core/utils/file_size_formatter.dart';
import 'package:archonex_converter/l10n/app_localizations.dart';

/// What the run produced, and the way to get all of it off the device at once.
///
/// Individual results are saved from their own rows; this is the shortcut for
/// the common case, which is wanting every one of them.
class BatchResultsCard extends StatelessWidget {
  const BatchResultsCard({
    required this.convertedCount,
    required this.totalCount,
    required this.totalBytes,
    required this.isSaving,
    required this.onSaveAllPressed,
    super.key,
  });

  static const double _padding = AppSpacing.lg;
  static const double _iconSize = 28;

  final int convertedCount;
  final int totalCount;
  final int totalBytes;
  final bool isSaving;
  final VoidCallback onSaveAllPressed;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final String convertedCountLabel = convertedCount == totalCount
        ? l10n.photosConvertedAll(totalCount)
        : l10n.photosConvertedProgress(convertedCount, totalCount);

    return Container(
      padding: const EdgeInsets.all(_padding),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                Icons.check_circle_outline_rounded,
                size: _iconSize,
                color: colors.onPrimaryContainer,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      l10n.resultsTitle,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colors.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '$convertedCountLabel'
                      ' · ${FileSizeFormatter.format(totalBytes)}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: colors.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.tonalIcon(
            onPressed: isSaving ? null : onSaveAllPressed,
            icon: const Icon(Icons.download_rounded),
            label: Text(isSaving ? l10n.savingLabel : l10n.saveAllLabel),
          ),
        ],
      ),
    );
  }
}
