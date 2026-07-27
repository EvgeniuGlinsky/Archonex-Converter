import 'package:flutter/material.dart';

import 'package:archonex/core/constants/app_radius.dart';
import 'package:archonex/core/constants/app_spacing.dart';
import 'package:archonex/core/constants/app_strings.dart';
import 'package:archonex/core/utils/file_size_formatter.dart';
import 'package:archonex/project_files/features/media_converter/domain/models/converted_file.dart';

/// The finished file plus the way to get it off the device.
class ConversionResultCard extends StatelessWidget {
  const ConversionResultCard({
    required this.file,
    required this.isSaving,
    required this.onDownloadPressed,
    super.key,
  });

  static const double _padding = AppSpacing.lg;
  static const double _iconSize = 28;

  final ConvertedFile file;
  final bool isSaving;
  final VoidCallback onDownloadPressed;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

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
                      AppStrings.resultTitle,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colors.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${file.name} · '
                      '${FileSizeFormatter.format(file.sizeInBytes)}',
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
            onPressed: isSaving ? null : onDownloadPressed,
            icon: const Icon(Icons.download_rounded),
            label: Text(
              isSaving ? AppStrings.savingLabel : AppStrings.downloadLabel,
            ),
          ),
        ],
      ),
    );
  }
}
