import 'package:flutter/material.dart';

import 'package:archonex/core/constants/app_spacing.dart';
import 'package:archonex/l10n/app_localizations.dart';
import 'package:archonex/project_files/features/converter_shared/ui/widgets/responsive_tile_grid.dart';
import 'package:archonex/project_files/features/converter_shared/ui/widgets/section_title.dart';
import 'package:archonex/project_files/features/converter_shared/ui/widgets/target_format_tile.dart';
import 'package:archonex/project_files/features/image_converter/domain/models/image_format.dart';
import 'package:archonex/project_files/features/image_converter/ui/mappers/image_format_ui.dart';

typedef ImageFormatCallback = void Function(ImageFormat format);

/// Every format the batch can be written as.
///
/// Unlike the media converter there is nothing to group by: a still picture
/// only ever becomes another still picture, so one grid says it all.
class TargetFormatGrid extends StatelessWidget {
  const TargetFormatGrid({
    required this.targets,
    required this.selected,
    required this.isEnabled,
    required this.onSelected,
    super.key,
  });

  final List<ImageFormat> targets;
  final ImageFormat? selected;
  final bool isEnabled;
  final ImageFormatCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SectionTitle(AppLocalizations.of(context)!.convertToTitle),
        const SizedBox(height: AppSpacing.sm),
        ResponsiveTileGrid(
          tiles: targets
              .map(
                (format) => TargetFormatTile(
                  label: format.label,
                  icon: format.icon,
                  isSelected: format == selected,
                  isEnabled: isEnabled,
                  onPressed: () => onSelected(format),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
