import 'package:flutter/material.dart';

import 'package:archonex_converter/core/constants/app_radius.dart';
import 'package:archonex_converter/core/constants/app_spacing.dart';
import 'package:archonex_converter/core/utils/file_size_formatter.dart';
import 'package:archonex_converter/l10n/app_localizations.dart';
import 'package:archonex_converter/project_files/features/converter_shared/domain/models/source_file.dart';
import 'package:archonex_converter/project_files/features/converter_shared/ui/mappers/converter_limits_ui.dart';
import 'package:archonex_converter/project_files/features/converter_shared/ui/widgets/format_badge.dart';
import 'package:archonex_converter/project_files/features/media_converter/domain/models/media_format.dart';
import 'package:archonex_converter/project_files/features/media_converter/ui/mappers/media_format_ui.dart';

/// Upload slot: a call to action while empty, the picked file once filled.
class SourceFileCard extends StatelessWidget {
  const SourceFileCard({
    required this.file,
    required this.isEnabled,
    required this.onPickPressed,
    required this.onRemovePressed,
    super.key,
  });

  static const double _padding = AppSpacing.lg;
  static const double _iconSize = 28;

  final SourceFile? file;
  final bool isEnabled;
  final VoidCallback onPickPressed;
  final VoidCallback onRemovePressed;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final SourceFile? selected = file;

    return Container(
      padding: const EdgeInsets.all(_padding),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: selected == null
          ? _EmptyState(
              isEnabled: isEnabled,
              onPickPressed: onPickPressed,
            )
          : _SelectedState(
              file: selected,
              isEnabled: isEnabled,
              onRemovePressed: onRemovePressed,
            ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isEnabled, required this.onPickPressed});

  final bool isEnabled;
  final VoidCallback onPickPressed;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          ConverterLimitsUi.mediaEmptyHint(context),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton.icon(
          onPressed: isEnabled ? onPickPressed : null,
          icon: const Icon(Icons.upload_file_outlined),
          label: Text(AppLocalizations.of(context)!.chooseFileLabel),
        ),
      ],
    );
  }
}

class _SelectedState extends StatelessWidget {
  const _SelectedState({
    required this.file,
    required this.isEnabled,
    required this.onRemovePressed,
  });

  final SourceFile file;
  final bool isEnabled;
  final VoidCallback onRemovePressed;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final MediaFormat? format = MediaFormat.fromExtension(file.extension);

    return Row(
      children: <Widget>[
        Icon(
          Icons.insert_drive_file_outlined,
          size: SourceFileCard._iconSize,
          color: colors.primary,
        ),
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
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: <Widget>[
                  Text(
                    FileSizeFormatter.format(file.sizeInBytes),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  if (format != null) ...<Widget>[
                    const SizedBox(width: AppSpacing.sm),
                    FormatBadge(format.label, tone: format.kind.badgeTone),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        IconButton(
          onPressed: isEnabled ? onRemovePressed : null,
          tooltip: AppLocalizations.of(context)!.removeFileLabel,
          icon: const Icon(Icons.close_rounded),
        ),
      ],
    );
  }
}
