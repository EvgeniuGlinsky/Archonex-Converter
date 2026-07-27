import 'package:flutter/material.dart';

import 'package:archonex/core/constants/app_strings.dart';
import 'package:archonex/core/widgets/app_primary_button.dart';
import 'package:archonex/project_files/features/media_converter/domain/models/media_format.dart';
import 'package:archonex/project_files/features/media_converter/ui/bloc/media_converter_bloc.dart';

/// The primary action of the screen. Disabled until a file and a target
/// format are both chosen.
class MediaConverterActions extends StatelessWidget {
  const MediaConverterActions({
    required this.state,
    required this.onConvertPressed,
    super.key,
  });

  final MediaConverterState state;
  final VoidCallback onConvertPressed;

  @override
  Widget build(BuildContext context) {
    final MediaFormat? target = state.target;

    final String label;
    if (state.isConverting) {
      label = AppStrings.convertingLabel;
    } else if (target == null) {
      label = AppStrings.convertLabel;
    } else {
      label = AppStrings.convertToLabel(target.label);
    }

    return AppPrimaryButton(
      label: label,
      onPressed: state.canConvert ? onConvertPressed : null,
    );
  }
}
