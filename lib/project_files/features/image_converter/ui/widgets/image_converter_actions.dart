import 'package:flutter/material.dart';

import 'package:archonex_converter/core/widgets/app_primary_button.dart';
import 'package:archonex_converter/l10n/app_localizations.dart';
import 'package:archonex_converter/project_files/features/image_converter/domain/models/image_format.dart';
import 'package:archonex_converter/project_files/features/image_converter/ui/bloc/image_converter_bloc.dart';

/// The primary action of the screen. Disabled until photos and a target format
/// are both chosen.
class ImageConverterActions extends StatelessWidget {
  const ImageConverterActions({
    required this.state,
    required this.onConvertPressed,
    super.key,
  });

  final ImageConverterState state;
  final VoidCallback onConvertPressed;

  @override
  Widget build(BuildContext context) {
    final ImageFormat? target = state.target;
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    final String label;
    if (state.isConverting) {
      label = l10n.convertingLabel;
    } else if (target == null) {
      label = l10n.convertLabel;
    } else {
      label = l10n.convertAllToLabel(state.totalCount, target.label);
    }

    return AppPrimaryButton(
      label: label,
      onPressed: state.canConvert ? onConvertPressed : null,
    );
  }
}
