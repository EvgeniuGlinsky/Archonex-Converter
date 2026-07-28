import 'package:flutter/material.dart';

import 'package:archonex_converter/core/constants/app_radius.dart';
import 'package:archonex_converter/core/constants/app_spacing.dart';
import 'package:archonex_converter/core/utils/file_size_formatter.dart';
import 'package:archonex_converter/l10n/app_localizations.dart';
import 'package:archonex_converter/project_files/features/converter_shared/domain/models/converted_file.dart';
import 'package:archonex_converter/project_files/features/converter_shared/ui/mappers/conversion_failure_ui.dart';
import 'package:archonex_converter/project_files/features/converter_shared/ui/widgets/format_badge.dart';
import 'package:archonex_converter/project_files/features/image_converter/domain/models/image_conversion_item.dart';
import 'package:archonex_converter/project_files/features/image_converter/domain/models/image_format.dart';
import 'package:archonex_converter/project_files/features/image_converter/ui/mappers/image_format_ui.dart';

/// One photo in the batch: what it is, where it got to, and what can be done
/// with it.
class SourceImageTile extends StatelessWidget {
  const SourceImageTile({
    required this.item,
    required this.canEdit,
    required this.canSave,
    required this.onRemovePressed,
    required this.onSavePressed,
    super.key,
  });

  static const double _padding = AppSpacing.md;
  static const double _iconSize = 24;
  static const double _spinnerSize = 18;
  static const double _spinnerStroke = 2;

  final ImageConversionItem item;

  /// `false` while a run is in flight, when the batch must not change.
  final bool canEdit;

  /// `false` while a save is already running.
  final bool canSave;

  final VoidCallback onRemovePressed;
  final VoidCallback onSavePressed;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(_padding),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        children: <Widget>[
          _Leading(status: item.status),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: _Details(item: item)),
          const SizedBox(width: AppSpacing.sm),
          if (item.status == ImageItemStatus.done)
            IconButton(
              onPressed: canSave ? onSavePressed : null,
              tooltip: AppLocalizations.of(context)!.saveLabel,
              icon: const Icon(Icons.download_rounded),
            ),
          IconButton(
            onPressed: canEdit ? onRemovePressed : null,
            tooltip: AppLocalizations.of(context)!.removeFileLabel,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

/// The glyph that says where this photo got to.
class _Leading extends StatelessWidget {
  const _Leading({required this.status});

  final ImageItemStatus status;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    if (status == ImageItemStatus.converting) {
      return const SizedBox.square(
        dimension: SourceImageTile._spinnerSize,
        child: CircularProgressIndicator(
          strokeWidth: SourceImageTile._spinnerStroke,
        ),
      );
    }

    return Icon(
      switch (status) {
        ImageItemStatus.pending => Icons.image_outlined,
        ImageItemStatus.done => Icons.check_circle_outline_rounded,
        ImageItemStatus.failed => Icons.error_outline_rounded,
        ImageItemStatus.converting => Icons.image_outlined,
      },
      size: SourceImageTile._iconSize,
      color: switch (status) {
        ImageItemStatus.done => colors.primary,
        ImageItemStatus.failed => colors.error,
        ImageItemStatus.pending || ImageItemStatus.converting =>
          colors.onSurfaceVariant,
      },
    );
  }
}

/// Name on top, and underneath it whatever is most worth knowing right now:
/// the reason it failed, the result it produced, or what it is.
class _Details extends StatelessWidget {
  const _Details({required this.item});

  final ImageConversionItem item;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final ImageFormat? format =
        ImageFormat.fromExtension(item.source.extension);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          item.source.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        if (item.failure != null)
          Text(
            item.failure!.message(context),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(color: colors.error),
          )
        else
          Row(
            children: <Widget>[
              Flexible(
                child: Text(
                  _sizeLine(item),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
              if (format != null) ...<Widget>[
                const SizedBox(width: AppSpacing.sm),
                FormatBadge(format.label, tone: format.badgeTone),
              ],
            ],
          ),
      ],
    );
  }

  /// Once a result exists the interesting number is what the conversion did to
  /// the size, so both ends are shown rather than only the original.
  static String _sizeLine(ImageConversionItem item) {
    final String source = FileSizeFormatter.format(item.source.sizeInBytes);
    final ConvertedFile? result = item.result;

    if (result == null) {
      return source;
    }

    return '$source → ${FileSizeFormatter.format(result.sizeInBytes)}';
  }
}
