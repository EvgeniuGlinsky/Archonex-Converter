import 'package:flutter/material.dart';

import 'package:archonex/core/constants/app_durations.dart';
import 'package:archonex/core/constants/app_radius.dart';
import 'package:archonex/core/constants/app_spacing.dart';
import 'package:archonex/core/constants/app_strings.dart';
import 'package:archonex/project_files/features/media_converter/domain/models/audio_bitrate_option.dart';
import 'package:archonex/project_files/features/media_converter/domain/models/conversion_settings.dart';
import 'package:archonex/project_files/features/media_converter/domain/models/frame_rate_option.dart';
import 'package:archonex/project_files/features/media_converter/domain/models/media_format.dart';
import 'package:archonex/project_files/features/media_converter/domain/models/video_resolution.dart';
import 'package:archonex/project_files/features/media_converter/ui/widgets/advanced_setting_row.dart';
import 'package:archonex/project_files/features/media_converter/ui/widgets/setting_dropdown.dart';
import 'package:archonex/project_files/features/media_converter/ui/widgets/video_quality_slider.dart';

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

  static const double _padding = AppSpacing.lg;
  static const double _gap = AppSpacing.lg;
  static const double _collapsedTurns = 0;
  static const double _expandedTurns = 0.5;

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
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _Header(isExpanded: isExpanded, onToggle: onToggle),
          AnimatedCrossFade(
            duration: AppDurations.shortAnimation,
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(
                _padding,
                0,
                _padding,
                _padding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _fields(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _fields() {
    return <Widget>[
      if (target.supportsResolution) ...<Widget>[
        AdvancedSettingRow(
          label: AppStrings.resolutionLabel,
          child: SettingDropdown<VideoResolution>(
            value: settings.resolution,
            options: VideoResolution.values,
            labelOf: (option) => option.label,
            isEnabled: isEnabled,
            onChanged: onResolutionChanged,
          ),
        ),
        const SizedBox(height: _gap),
      ],
      if (target.supportsFrameRate) ...<Widget>[
        AdvancedSettingRow(
          label: AppStrings.frameRateLabel,
          child: SettingDropdown<FrameRateOption>(
            value: settings.frameRate,
            options: FrameRateOption.values,
            labelOf: (option) => option.label,
            isEnabled: isEnabled,
            onChanged: onFrameRateChanged,
          ),
        ),
        const SizedBox(height: _gap),
      ],
      if (target.supportsVideoQuality) ...<Widget>[
        AdvancedSettingRow(
          label: AppStrings.videoQualityLabel,
          child: VideoQualitySlider(
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
          title: const Text(AppStrings.keepAudioLabel),
          subtitle: const Text(AppStrings.keepAudioHint),
          onChanged: isEnabled ? onKeepAudioChanged : null,
        ),
        const SizedBox(height: _gap),
      ],
      // A bitrate the output will not carry is not worth asking about.
      if (target.supportsAudioBitrate && settings.keepAudio) ...<Widget>[
        AdvancedSettingRow(
          label: AppStrings.audioBitrateLabel,
          child: SettingDropdown<AudioBitrateOption>(
            value: settings.audioBitrate,
            options: AudioBitrateOption.values,
            labelOf: (option) => option.label,
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
          child: const Text(AppStrings.resetToPresetLabel),
        ),
      ),
    ];
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.isExpanded, required this.onToggle});

  final bool isExpanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.all(AdvancedSettingsPanel._padding),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    AppStrings.advancedTitle,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    AppStrings.advancedHint,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedRotation(
              duration: AppDurations.shortAnimation,
              turns: isExpanded
                  ? AdvancedSettingsPanel._expandedTurns
                  : AdvancedSettingsPanel._collapsedTurns,
              child: const Icon(Icons.expand_more_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
