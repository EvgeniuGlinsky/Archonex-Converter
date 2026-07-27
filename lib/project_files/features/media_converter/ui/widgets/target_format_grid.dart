import 'package:flutter/material.dart';

import 'package:archonex_converter/core/constants/app_spacing.dart';
import 'package:archonex_converter/l10n/app_localizations.dart';
import 'package:archonex_converter/project_files/features/converter_shared/ui/widgets/responsive_tile_grid.dart';
import 'package:archonex_converter/project_files/features/converter_shared/ui/widgets/section_title.dart';
import 'package:archonex_converter/project_files/features/converter_shared/ui/widgets/target_format_tile.dart';
import 'package:archonex_converter/project_files/features/media_converter/domain/models/media_format.dart';
import 'package:archonex_converter/project_files/features/media_converter/ui/mappers/media_format_ui.dart';

typedef TargetFormatCallback = void Function(MediaFormat format);

/// Every format the picked file can become, grouped by what it would produce.
///
/// Only reachable formats are passed in, so nothing here is ever rendered as a
/// dead end: a tile that exists can always be tapped once the screen is idle.
class TargetFormatGrid extends StatelessWidget {
  const TargetFormatGrid({
    required this.targets,
    required this.selected,
    required this.isEnabled,
    required this.onSelected,
    super.key,
  });

  final List<MediaFormat> targets;
  final MediaFormat? selected;
  final bool isEnabled;
  final TargetFormatCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SectionTitle(AppLocalizations.of(context)!.convertToTitle),
        for (final MediaFormatKind kind in MediaFormatKind.values)
          ..._group(context, kind),
      ],
    );
  }

  List<Widget> _group(BuildContext context, MediaFormatKind kind) {
    final List<MediaFormat> formats =
        targets.where((format) => format.kind == kind).toList(growable: false);

    if (formats.isEmpty) {
      return const <Widget>[];
    }

    return <Widget>[
      const SizedBox(height: AppSpacing.md),
      SectionTitle(kind.title(context)),
      const SizedBox(height: AppSpacing.sm),
      ResponsiveTileGrid(
        tiles: formats
            .map(
              (format) => TargetFormatTile(
                label: format.label,
                icon: format.kind.icon,
                isSelected: format == selected,
                isEnabled: isEnabled,
                onPressed: () => onSelected(format),
              ),
            )
            .toList(),
      ),
    ];
  }
}
