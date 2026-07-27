import 'package:flutter/material.dart';

import 'package:archonex/core/constants/app_breakpoints.dart';
import 'package:archonex/core/constants/app_spacing.dart';
import 'package:archonex/core/constants/app_strings.dart';
import 'package:archonex/project_files/features/media_converter/domain/models/media_format.dart';
import 'package:archonex/project_files/features/media_converter/ui/mappers/media_format_ui.dart';
import 'package:archonex/project_files/features/media_converter/ui/widgets/section_title.dart';
import 'package:archonex/project_files/features/media_converter/ui/widgets/target_format_tile.dart';

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

  static const int _compactColumns = 3;
  static const int _mediumColumns = 4;
  static const int _expandedColumns = 6;
  static const double _tileAspectRatio = 1.5;
  static const double _spacing = AppSpacing.sm;

  final List<MediaFormat> targets;
  final MediaFormat? selected;
  final bool isEnabled;
  final TargetFormatCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SectionTitle(AppStrings.convertToTitle),
        for (final MediaFormatKind kind in MediaFormatKind.values)
          ..._group(kind),
      ],
    );
  }

  List<Widget> _group(MediaFormatKind kind) {
    final List<MediaFormat> formats =
        targets.where((format) => format.kind == kind).toList(growable: false);

    if (formats.isEmpty) {
      return const <Widget>[];
    }

    return <Widget>[
      const SizedBox(height: AppSpacing.md),
      SectionTitle(kind.title),
      const SizedBox(height: AppSpacing.sm),
      _FormatRow(
        formats: formats,
        selected: selected,
        isEnabled: isEnabled,
        onSelected: onSelected,
      ),
    ];
  }
}

/// The tiles of one group, laid out in as many columns as the width allows.
///
/// The count comes from [LayoutBuilder] rather than `MediaQuery`: the screen
/// layout caps content at `AppBreakpoints.maxContentWidth` and pads it, so the
/// window width overstates the space available by a wide margin on desktop.
class _FormatRow extends StatelessWidget {
  const _FormatRow({
    required this.formats,
    required this.selected,
    required this.isEnabled,
    required this.onSelected,
  });

  final List<MediaFormat> formats;
  final MediaFormat? selected;
  final bool isEnabled;
  final TargetFormatCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => GridView.count(
        crossAxisCount: _columnsFor(constraints.maxWidth),
        childAspectRatio: TargetFormatGrid._tileAspectRatio,
        crossAxisSpacing: TargetFormatGrid._spacing,
        mainAxisSpacing: TargetFormatGrid._spacing,
        // The body is already a ListView; this one only measures itself.
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: formats
            .map(
              (format) => TargetFormatTile(
                format: format,
                isSelected: format == selected,
                isEnabled: isEnabled,
                onPressed: () => onSelected(format),
              ),
            )
            .toList(),
      ),
    );
  }

  static int _columnsFor(double width) {
    if (width < AppBreakpoints.compact) {
      return TargetFormatGrid._compactColumns;
    }
    if (width < AppBreakpoints.medium) {
      return TargetFormatGrid._mediumColumns;
    }

    return TargetFormatGrid._expandedColumns;
  }
}
