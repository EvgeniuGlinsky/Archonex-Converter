import 'package:flutter/material.dart';

import 'package:archonex_converter/core/constants/app_file_limits.dart';
import 'package:archonex_converter/core/constants/app_radius.dart';
import 'package:archonex_converter/core/constants/app_spacing.dart';
import 'package:archonex_converter/core/utils/file_size_formatter.dart';
import 'package:archonex_converter/l10n/app_localizations.dart';
import 'package:archonex_converter/project_files/features/image_converter/domain/models/image_conversion_item.dart';
import 'package:archonex_converter/project_files/features/image_converter/ui/widgets/source_image_tile.dart';

/// The batch: a call to action while empty, the photos once filled.
class SourceImageList extends StatelessWidget {
  const SourceImageList({
    required this.items,
    required this.totalBytes,
    required this.canPick,
    required this.canEdit,
    required this.canSave,
    required this.onPickPressed,
    required this.onClearPressed,
    required this.onRemovePressed,
    required this.onSavePressed,
    super.key,
  });

  static const double _gap = AppSpacing.sm;

  final List<ImageConversionItem> items;
  final int totalBytes;
  final bool canPick;
  final bool canEdit;
  final bool canSave;
  final VoidCallback onPickPressed;
  final VoidCallback onClearPressed;
  final ValueChanged<int> onRemovePressed;
  final ValueChanged<int> onSavePressed;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return _EmptyState(canPick: canPick, onPickPressed: onPickPressed);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _SummaryRow(
          count: items.length,
          totalBytes: totalBytes,
          canEdit: canEdit,
          onClearPressed: onClearPressed,
        ),
        const SizedBox(height: _gap),
        for (int index = 0; index < items.length; index++) ...<Widget>[
          if (index > 0) const SizedBox(height: _gap),
          SourceImageTile(
            item: items[index],
            canEdit: canEdit,
            canSave: canSave,
            onRemovePressed: () => onRemovePressed(index),
            onSavePressed: () => onSavePressed(index),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: canPick ? onPickPressed : null,
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: Text(AppLocalizations.of(context)!.addMorePhotosLabel),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.canPick, required this.onPickPressed});

  final bool canPick;
  final VoidCallback onPickPressed;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            AppLocalizations.of(context)!.noPhotosHint(
              AppFileLimits.maxBatchFiles,
            ),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: canPick ? onPickPressed : null,
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: Text(AppLocalizations.of(context)!.addPhotosLabel),
          ),
        ],
      ),
    );
  }
}

/// How much has been picked, and the way to drop all of it at once.
class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.count,
    required this.totalBytes,
    required this.canEdit,
    required this.onClearPressed,
  });

  final int count;
  final int totalBytes;
  final bool canEdit;
  final VoidCallback onClearPressed;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            AppLocalizations.of(context)!.photosSelected(
              count,
              FileSizeFormatter.format(totalBytes),
            ),
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        TextButton(
          onPressed: canEdit ? onClearPressed : null,
          child: Text(AppLocalizations.of(context)!.clearPhotosLabel),
        ),
      ],
    );
  }
}
