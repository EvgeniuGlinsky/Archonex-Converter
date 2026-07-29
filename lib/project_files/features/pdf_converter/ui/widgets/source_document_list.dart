import 'package:flutter/material.dart';

import 'package:archonex_converter/core/constants/app_radius.dart';
import 'package:archonex_converter/core/constants/app_spacing.dart';
import 'package:archonex_converter/core/utils/file_size_formatter.dart';
import 'package:archonex_converter/l10n/app_localizations.dart';
import 'package:archonex_converter/project_files/features/converter_shared/domain/models/source_file.dart';
import 'package:archonex_converter/project_files/features/converter_shared/ui/mappers/converter_limits_ui.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/ui/widgets/source_document_tile.dart';

/// The selection: a call to action while empty, the files once filled.
class SourceDocumentList extends StatelessWidget {
  const SourceDocumentList({
    required this.sources,
    required this.totalBytes,
    required this.canPick,
    required this.canEdit,
    required this.onPickPressed,
    required this.onClearPressed,
    required this.onRemovePressed,
    super.key,
  });

  static const double _gap = AppSpacing.sm;

  final List<SourceFile> sources;
  final int totalBytes;
  final bool canPick;
  final bool canEdit;
  final VoidCallback onPickPressed;
  final VoidCallback onClearPressed;
  final ValueChanged<int> onRemovePressed;

  @override
  Widget build(BuildContext context) {
    if (sources.isEmpty) {
      return _EmptyState(canPick: canPick, onPickPressed: onPickPressed);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _SummaryRow(
          count: sources.length,
          totalBytes: totalBytes,
          canEdit: canEdit,
          onClearPressed: onClearPressed,
        ),
        const SizedBox(height: _gap),
        for (int index = 0; index < sources.length; index++) ...<Widget>[
          if (index > 0) const SizedBox(height: _gap),
          SourceDocumentTile(
            file: sources[index],
            canRemove: canEdit,
            onRemovePressed: () => onRemovePressed(index),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: canPick ? onPickPressed : null,
            icon: const Icon(Icons.add_rounded),
            label: Text(AppLocalizations.of(context)!.addMoreFilesLabel),
          ),
        ),
      ],
    );
  }
}

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
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            l10n.filesSelected(count, FileSizeFormatter.format(totalBytes)),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        TextButton(
          onPressed: canEdit ? onClearPressed : null,
          child: Text(l10n.clearFilesLabel),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.canPick, required this.onPickPressed});

  static const double _padding = AppSpacing.xl;

  final bool canPick;
  final VoidCallback onPickPressed;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(_padding),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        children: <Widget>[
          Text(
            ConverterLimitsUi.pdfEmptyHint(context),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.tonalIcon(
            onPressed: canPick ? onPickPressed : null,
            icon: const Icon(Icons.add_rounded),
            label: Text(l10n.addFilesLabel),
          ),
        ],
      ),
    );
  }
}
