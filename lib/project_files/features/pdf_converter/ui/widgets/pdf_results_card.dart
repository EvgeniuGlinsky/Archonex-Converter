import 'package:flutter/material.dart';

import 'package:archonex_converter/core/constants/app_radius.dart';
import 'package:archonex_converter/core/constants/app_spacing.dart';
import 'package:archonex_converter/core/utils/file_size_formatter.dart';
import 'package:archonex_converter/l10n/app_localizations.dart';
import 'package:archonex_converter/project_files/features/converter_shared/domain/models/converted_file.dart';

/// What the run produced.
///
/// Shows one row per result because a rasterised PDF hands back a page each,
/// and each page is worth saving on its own. A merged PDF lands here as a
/// single row, which is the same widget doing the same thing with one item.
class PdfResultsCard extends StatelessWidget {
  const PdfResultsCard({
    required this.results,
    required this.isSaving,
    required this.onSavePressed,
    required this.onSaveAllPressed,
    super.key,
  });

  static const double _padding = AppSpacing.lg;
  static const double _iconSize = 28;

  /// Beyond this the list is summarised instead of listed: a two hundred page
  /// document would otherwise bury the save button under its own output.
  static const int _maxListedRows = 12;

  final List<ConvertedFile> results;
  final bool isSaving;
  final ValueChanged<int> onSavePressed;
  final VoidCallback onSaveAllPressed;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    final int totalBytes =
        results.fold(0, (sum, file) => sum + file.sizeInBytes);

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
                      '${l10n.pagesConverted(results.length)}'
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
          if (results.length <= _maxListedRows)
            for (int index = 0; index < results.length; index++)
              _ResultRow(
                file: results[index],
                isSaving: isSaving,
                onSavePressed: () => onSavePressed(index),
              ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.tonalIcon(
            onPressed: isSaving ? null : onSaveAllPressed,
            icon: const Icon(Icons.download_rounded),
            label: Text(
              isSaving
                  ? l10n.savingLabel
                  : results.length == 1
                      ? l10n.saveLabel
                      : l10n.saveAllLabel,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.file,
    required this.isSaving,
    required this.onSavePressed,
  });

  final ConvertedFile file;
  final bool isSaving;
  final VoidCallback onSavePressed;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              '${file.name} · ${FileSizeFormatter.format(file.sizeInBytes)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onPrimaryContainer,
              ),
            ),
          ),
          IconButton(
            onPressed: isSaving ? null : onSavePressed,
            tooltip: AppLocalizations.of(context)!.saveLabel,
            icon: Icon(
              Icons.download_rounded,
              color: colors.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}
