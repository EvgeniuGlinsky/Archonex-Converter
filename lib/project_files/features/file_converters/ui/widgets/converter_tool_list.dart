import 'package:flutter/material.dart';

import 'package:archonex/core/constants/app_spacing.dart';
import 'package:archonex/project_files/features/file_converters/domain/models/converter_tool.dart';
import 'package:archonex/project_files/features/file_converters/ui/widgets/converter_tool_tile.dart';

typedef ConverterToolSelectedCallback = void Function(ConverterTool tool);

/// Scrollable list of the converters in the catalogue.
class ConverterToolList extends StatelessWidget {
  const ConverterToolList({
    required this.tools,
    required this.onToolSelected,
    super.key,
  });

  final List<ConverterTool> tools;
  final ConverterToolSelectedCallback onToolSelected;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: tools.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final ConverterTool tool = tools[index];

        return ConverterToolTile(
          tool: tool,
          onTap: tool.isAvailable ? () => onToolSelected(tool) : null,
        );
      },
    );
  }
}
