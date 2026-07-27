import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:archonex_converter/core/widgets/app_screen_header.dart';
import 'package:archonex_converter/core/widgets/app_screen_layout.dart';
import 'package:archonex_converter/l10n/app_localizations.dart';
import 'package:archonex_converter/project_files/features/media_converter/ui/bloc/media_converter_bloc.dart';
import 'package:archonex_converter/project_files/features/media_converter/ui/widgets/media_converter_actions.dart';
import 'package:archonex_converter/project_files/features/media_converter/ui/widgets/media_converter_body.dart';
import 'package:archonex_converter/project_files/features/media_converter/ui/widgets/media_converter_callbacks.dart';

/// Errors live in the body banner; this listener only announces a finished
/// save, so the same problem is never reported twice.
class MediaConverterView extends StatelessWidget {
  const MediaConverterView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<MediaConverterBloc, MediaConverterState>(
      listenWhen: (previous, current) =>
          previous.status != current.status &&
          current.status == MediaConverterStatus.saved,
      listener: _onSaved,
      child: Scaffold(
        appBar: AppBar(),
        body: BlocBuilder<MediaConverterBloc, MediaConverterState>(
          builder: (context, state) => AppScreenLayout(
            header: AppScreenHeader(
              title: AppLocalizations.of(context)!.mediaConverterTitle,
              subtitle:
                  AppLocalizations.of(context)!.mediaConverterScreenSubtitle,
            ),
            body: MediaConverterBody(
              state: state,
              callbacks: _callbacks(context),
            ),
            bottom: MediaConverterActions(
              state: state,
              onConvertPressed: () => _add(context, const ConversionRequested()),
            ),
          ),
        ),
      ),
    );
  }

  MediaConverterCallbacks _callbacks(BuildContext context) {
    return MediaConverterCallbacks(
      onPickPressed: () => _add(context, const SourceFilePickRequested()),
      onRemovePressed: () => _add(context, const SourceFileCleared()),
      onTargetSelected: (format) => _add(context, TargetFormatSelected(format)),
      onQualityChanged: (quality) =>
          _add(context, QualityPresetChanged(quality)),
      onAdvancedToggled: () => _add(context, const AdvancedPanelToggled()),
      onResolutionChanged: (resolution) =>
          _add(context, ResolutionChanged(resolution)),
      onFrameRateChanged: (frameRate) =>
          _add(context, FrameRateChanged(frameRate)),
      onVideoQualityChanged: (value) =>
          _add(context, VideoQualityChanged(value)),
      onAudioBitrateChanged: (bitrate) =>
          _add(context, AudioBitrateChanged(bitrate)),
      onKeepAudioChanged: (keepAudio) =>
          _add(context, KeepAudioToggled(keepAudio)),
      onAdvancedReset: () => _add(context, const AdvancedSettingsReset()),
      onCancelPressed: () => _add(context, const ConversionCancelled()),
      onDownloadPressed: () =>
          _add(context, const ConvertedFileSaveRequested()),
    );
  }

  void _add(BuildContext context, MediaConverterEvent event) {
    context.read<MediaConverterBloc>().add(event);
  }

  void _onSaved(BuildContext context, MediaConverterState state) {
    final String? location = state.savedLocation;
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          location == null ? l10n.downloadStarted : l10n.savedTo(location),
        ),
      ),
    );
  }
}
