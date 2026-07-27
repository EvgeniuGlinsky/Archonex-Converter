import 'package:flutter/material.dart';

import 'package:archonex_converter/core/widgets/app_primary_button.dart';
import 'package:archonex_converter/l10n/app_localizations.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/domain/models/pdf_target.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/ui/bloc/pdf_converter_bloc.dart';

/// The primary action. Disabled until files and a target are both chosen.
class PdfConverterActions extends StatelessWidget {
  const PdfConverterActions({
    required this.state,
    required this.onConvertPressed,
    super.key,
  });

  final PdfConverterState state;
  final VoidCallback onConvertPressed;

  @override
  Widget build(BuildContext context) {
    final PdfTarget? target = state.target;
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    final String label;
    if (state.isConverting) {
      label = l10n.convertingLabel;
    } else if (target == null) {
      label = l10n.convertLabel;
    } else {
      label = l10n.convertToLabel(target.label);
    }

    return AppPrimaryButton(
      label: label,
      onPressed: state.canConvert ? onConvertPressed : null,
    );
  }
}
