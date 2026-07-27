import 'package:flutter/material.dart';

import 'package:archonex_converter/core/constants/app_spacing.dart';
import 'package:archonex_converter/l10n/app_localizations.dart';
import 'package:archonex_converter/project_files/features/converter_shared/ui/widgets/responsive_tile_grid.dart';
import 'package:archonex_converter/project_files/features/converter_shared/ui/widgets/section_title.dart';
import 'package:archonex_converter/project_files/features/converter_shared/ui/widgets/target_format_tile.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/domain/models/pdf_target.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/ui/mappers/pdf_target_ui.dart';

/// What the current selection can become.
///
/// Short by design: the direction is already decided by what was picked, so
/// this is a choice between one and two tiles rather than a format matrix.
class PdfTargetGrid extends StatelessWidget {
  const PdfTargetGrid({
    required this.targets,
    required this.selected,
    required this.isEnabled,
    required this.onSelected,
    super.key,
  });

  final List<PdfTarget> targets;
  final PdfTarget? selected;
  final bool isEnabled;
  final ValueChanged<PdfTarget> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SectionTitle(AppLocalizations.of(context)!.convertToTitle),
        const SizedBox(height: AppSpacing.sm),
        ResponsiveTileGrid(
          tiles: <Widget>[
            for (final PdfTarget target in targets)
              TargetFormatTile(
                label: target.label,
                icon: target.icon,
                isSelected: target == selected,
                isEnabled: isEnabled,
                onPressed: () => onSelected(target),
              ),
          ],
        ),
      ],
    );
  }
}
