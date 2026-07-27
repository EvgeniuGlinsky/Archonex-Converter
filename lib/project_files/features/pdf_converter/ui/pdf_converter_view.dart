import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:archonex_converter/core/widgets/app_screen_header.dart';
import 'package:archonex_converter/core/widgets/app_screen_layout.dart';
import 'package:archonex_converter/l10n/app_localizations.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/ui/bloc/pdf_converter_bloc.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/ui/widgets/pdf_converter_actions.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/ui/widgets/pdf_converter_body.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/ui/widgets/pdf_converter_callbacks.dart';

/// Errors live in the body banner; this listener only announces a finished
/// save, so the same problem is never reported twice.
class PdfConverterView extends StatelessWidget {
  const PdfConverterView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<PdfConverterBloc, PdfConverterState>(
      listenWhen: (previous, current) =>
          previous.status != current.status &&
          current.status == PdfConverterStatus.saved,
      listener: _onSaved,
      child: Scaffold(
        appBar: AppBar(),
        body: BlocBuilder<PdfConverterBloc, PdfConverterState>(
          builder: (context, state) => AppScreenLayout(
            header: AppScreenHeader(
              title: AppLocalizations.of(context)!.pdfConverterTitle,
              subtitle:
                  AppLocalizations.of(context)!.pdfConverterScreenSubtitle,
            ),
            body: PdfConverterBody(
              state: state,
              callbacks: _callbacks(context),
            ),
            bottom: PdfConverterActions(
              state: state,
              onConvertPressed: () =>
                  _add(context, const PdfConversionRequested()),
            ),
          ),
        ),
      ),
    );
  }

  PdfConverterCallbacks _callbacks(BuildContext context) {
    return PdfConverterCallbacks(
      onPickPressed: () => _add(context, const PdfSourcesPickRequested()),
      onClearPressed: () => _add(context, const PdfSourcesCleared()),
      onRemovePressed: (index) => _add(context, PdfSourceRemoved(index)),
      onTargetSelected: (target) => _add(context, PdfTargetSelected(target)),
      onPageSizeChanged: (size) => _add(context, PdfPageSizeChanged(size)),
      onMarginChanged: (points) => _add(context, PdfMarginChanged(points)),
      onRasterDpiChanged: (dpi) => _add(context, PdfRasterDpiChanged(dpi)),
      onQualityChanged: (quality) => _add(context, PdfQualityChanged(quality)),
      onAdvancedToggled: () => _add(context, const PdfAdvancedPanelToggled()),
      onAdvancedReset: () => _add(context, const PdfAdvancedSettingsReset()),
      onCancelPressed: () => _add(context, const PdfConversionCancelled()),
      onSavePressed: (index) => _add(context, ConvertedPdfSaveRequested(index)),
      onSaveAllPressed: () =>
          _add(context, const AllConvertedPdfsSaveRequested()),
    );
  }

  void _add(BuildContext context, PdfConverterEvent event) {
    context.read<PdfConverterBloc>().add(event);
  }

  void _onSaved(BuildContext context, PdfConverterState state) {
    final String? location = state.savedLocation;
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          location == null
              ? l10n.downloadStarted
              : l10n.savedFiles(state.savedCount, location),
        ),
      ),
    );
  }
}
