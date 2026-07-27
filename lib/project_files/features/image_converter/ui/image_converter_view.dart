import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:archonex_converter/core/widgets/app_screen_header.dart';
import 'package:archonex_converter/core/widgets/app_screen_layout.dart';
import 'package:archonex_converter/l10n/app_localizations.dart';
import 'package:archonex_converter/project_files/features/image_converter/ui/bloc/image_converter_bloc.dart';
import 'package:archonex_converter/project_files/features/image_converter/ui/widgets/image_converter_actions.dart';
import 'package:archonex_converter/project_files/features/image_converter/ui/widgets/image_converter_body.dart';
import 'package:archonex_converter/project_files/features/image_converter/ui/widgets/image_converter_callbacks.dart';

/// Errors live in the body banner and on the individual rows; this listener
/// only announces a finished save, so the same problem is never reported twice.
class ImageConverterView extends StatelessWidget {
  const ImageConverterView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<ImageConverterBloc, ImageConverterState>(
      listenWhen: (previous, current) =>
          previous.status != current.status &&
          current.status == ImageConverterStatus.saved,
      listener: _onSaved,
      child: Scaffold(
        appBar: AppBar(),
        body: BlocBuilder<ImageConverterBloc, ImageConverterState>(
          builder: (context, state) => AppScreenLayout(
            header: AppScreenHeader(
              title: AppLocalizations.of(context)!.imageConverterTitle,
              subtitle:
                  AppLocalizations.of(context)!.imageConverterScreenSubtitle,
            ),
            body: ImageConverterBody(
              state: state,
              callbacks: _callbacks(context),
            ),
            bottom: ImageConverterActions(
              state: state,
              onConvertPressed: () => _add(context, const ConversionRequested()),
            ),
          ),
        ),
      ),
    );
  }

  ImageConverterCallbacks _callbacks(BuildContext context) {
    return ImageConverterCallbacks(
      onPickPressed: () => _add(context, const SourceImagesPickRequested()),
      onClearPressed: () => _add(context, const SourceImagesCleared()),
      onRemovePressed: (index) => _add(context, SourceImageRemoved(index)),
      onTargetSelected: (format) => _add(context, TargetFormatSelected(format)),
      onQualityChanged: (quality) =>
          _add(context, QualityPresetChanged(quality)),
      onAdvancedToggled: () => _add(context, const AdvancedPanelToggled()),
      onDimensionChanged: (limit) => _add(context, DimensionLimitChanged(limit)),
      onImageQualityChanged: (value) =>
          _add(context, ImageQualityChanged(value)),
      onBackgroundChanged: (background) =>
          _add(context, BackgroundChanged(background)),
      onKeepMetadataChanged: (keep) => _add(context, KeepMetadataToggled(keep)),
      onAdvancedReset: () => _add(context, const AdvancedSettingsReset()),
      onCancelPressed: () => _add(context, const ConversionCancelled()),
      onSavePressed: (index) =>
          _add(context, ConvertedImageSaveRequested(index)),
      onSaveAllPressed: () =>
          _add(context, const AllConvertedImagesSaveRequested()),
    );
  }

  void _add(BuildContext context, ImageConverterEvent event) {
    context.read<ImageConverterBloc>().add(event);
  }

  void _onSaved(BuildContext context, ImageConverterState state) {
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
