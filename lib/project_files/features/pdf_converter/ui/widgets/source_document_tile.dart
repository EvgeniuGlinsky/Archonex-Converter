import 'package:flutter/material.dart';

import 'package:archonex_converter/core/constants/app_radius.dart';
import 'package:archonex_converter/core/constants/app_spacing.dart';
import 'package:archonex_converter/core/utils/file_size_formatter.dart';
import 'package:archonex_converter/l10n/app_localizations.dart';
import 'package:archonex_converter/project_files/features/converter_shared/domain/models/source_file.dart';
import 'package:archonex_converter/project_files/features/converter_shared/ui/widgets/format_badge.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/domain/models/pdf_format.dart';

/// One picked file, with its format and its size.
class SourceDocumentTile extends StatelessWidget {
  const SourceDocumentTile({
    required this.file,
    required this.canRemove,
    required this.onRemovePressed,
    super.key,
  });

  static const double _padding = AppSpacing.md;

  final SourceFile file;
  final bool canRemove;
  final VoidCallback onRemovePressed;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final PdfFormat? format = PdfFormat.fromExtension(file.extension);

    return Container(
      padding: const EdgeInsets.all(_padding),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: <Widget>[
          FormatBadge(format?.label ?? file.extension.toUpperCase()),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  file.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  FileSizeFormatter.format(file.sizeInBytes),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: canRemove ? onRemovePressed : null,
            tooltip: AppLocalizations.of(context)!.removeFileLabel,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}
