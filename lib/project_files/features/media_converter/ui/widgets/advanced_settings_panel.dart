import 'package:flutter/material.dart';

import 'package:archonex/core/constants/app_spacing.dart';
import 'package:archonex/l10n/app_localizations.dart';
import 'package:archonex/project_files/features/converter_shared/ui/widgets/advanced_setting_row.dart';
import 'package:archonex/project_files/features/converter_shared/ui/widgets/advanced_settings_shell.dart';
import 'package:archonex/project_files/features/converter_shared/ui/widgets/quality_slider.dart';
import 'package:archonex/project_files/features/converter_shared/ui/widgets/setting_dropdown.dart';
import 'package:archonex/project_files/features/media_converter/domain/models/audio_bitrate_option.dart';
import 'package:archonex/project_files/features/media_converter/domain/models/conversion_settings.dart';
import 'package:archonex/project_files/features/media_converter/domain/models/frame_rate_option.dart';
import 'package:archonex/project_files/features/media_converter/domain/models/media_format.dart';
import 'package:archonex/project_files/features/media_converter/domain/models/video_resolution.dart';
import 'package:archonex/project_files/features/media_converter/ui/mappers/audio_bitrate_option_ui.dart';
import 'package:archonex/project_files/features/media_converter/ui/mappers/frame_rate_option_ui.dart';
import 'package:archonex/project_files/features/media_converter/ui/mappers/video_resolution_ui.dart';

/// Manual overrides on top of the quality preset.
///
/// Only the controls the chosen target can actually use are rendered — a frame
/// rate means nothing to a WAV file, and a bitrate means nothing to a FLAC one.
/// The same rule prunes the stored settings, so the panel always shows exactly
/// what is in state.
class AdvancedSettingsPanel extends StatelessWidget {
  const AdvancedSettingsPanel({
    required this.target,
    required this.settings,
    required this.isEnabled,
    required this.isExpanded,
    required this.onToggle,
    required this.onResolutionChanged,
    required this.onFrameRateChanged,
    required this.onVideoQualityChanged,
    required this.onAudioBitrateChanged,
    required this.onKeepAudioChanged,
    required this.onReset,
    super.key,
  });

  static const double _gap = AppSpacing.lg;

  final MediaFormat target;
  final ConversionSettings settings;
  final bool isEnabled;
  final bool isExpanded;
  final VoidCallback onToggle;
  final ValueChanged<VideoResolution> onResolutionChanged;
  final ValueChanged<FrameRateOption> onFrameRateChanged;
  final ValueChanged<int> onVideoQualityChanged;
  final ValueChanged<AudioBitrateOption> onAudioBitrateChanged;
  final ValueChanged<bool> onKeepAudioChanged;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return AdvancedSettingsShell(
      isExpanded: isExpanded,
      onToggle: onToggle,
      fields: _fields(context),
    );
  }

  List<Widget> _fields(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return <Widget>[
      if (target.supportsResolution) ...<Widget>[
        AdvancedSettingRow(
          label: l10n.resolutionLabel,
          child: SettingDropdown<VideoResolution>(
            value: settings.resolution,
            options: VideoResolution.values,
            labelOf: (option) => option.label(context),
            isEnabled: isEnabled,
            onChanged: onResolutionChanged,
          ),
        ),
        const SizedBox(height: _gap),
      ],
      if (target.supportsFrameRate) ...<Widget>[
        AdvancedSettingRow(
          label: l10n.frameRateLabel,
          child: SettingDropdown<FrameRateOption>(
            value: settings.frameRate,
            options: FrameRateOption.values,
            labelOf: (option) => option.label(context),
            isEnabled: isEnabled,
            onChanged: onFrameRateChanged,
          ),
        ),
        const SizedBox(height: _gap),
      ],
      if (target.supportsVideoQuality) ...<Widget>[
        AdvancedSettingRow(
          label: l10n.videoQualityLabel,
          child: QualitySlider(
            value: settings.effectiveVideoQuality,
            isEnabled: isEnabled,
            onChanged: onVideoQualityChanged,
          ),
        ),
        const SizedBox(height: _gap),
      ],
      if (target.supportsAudioToggle) ...<Widget>[
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          value: settings.keepAudio,
          title: Text(l10n.keepAudioLabel),
          subtitle: Text(l10n.keepAudioHint),
          onChanged: isEnabled ? onKeepAudioChanged : null,
        ),
        const SizedBox(height: _gap),
      ],
      // A bitrate the output will not carry is not worth asking about.
      if (target.supportsAudioBitrate && settings.keepAudio) ...<Widget>[
        AdvancedSettingRow(
          label: l10n.audioBitrateLabel,
          child: SettingDropdown<AudioBitrateOption>(
            value: settings.audioBitrate,
            options: AudioBitrateOption.values,
            labelOf: (option) => option.label(context),
            isEnabled: isEnabled,
            onChanged: onAudioBitrateChanged,
          ),
        ),
        const SizedBox(height: _gap),
      ],
      Align(
        alignment: Alignment.centerRight,
        child: TextButton(
          onPressed: isEnabled && !settings.isPresetOnly ? onReset : null,
          child: Text(l10n.resetToPresetLabel),
        ),
      ),
    ];
  }
}
