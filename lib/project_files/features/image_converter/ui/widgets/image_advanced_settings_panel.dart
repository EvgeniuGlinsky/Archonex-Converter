import 'package:flutter/material.dart';

import 'package:archonex_converter/core/constants/app_spacing.dart';
import 'package:archonex_converter/l10n/app_localizations.dart';
import 'package:archonex_converter/project_files/features/converter_shared/ui/widgets/advanced_setting_row.dart';
import 'package:archonex_converter/project_files/features/converter_shared/ui/widgets/advanced_settings_shell.dart';
import 'package:archonex_converter/project_files/features/converter_shared/ui/widgets/quality_slider.dart';
import 'package:archonex_converter/project_files/features/converter_shared/ui/widgets/setting_dropdown.dart';
import 'package:archonex_converter/project_files/features/image_converter/domain/models/image_background.dart';
import 'package:archonex_converter/project_files/features/image_converter/domain/models/image_conversion_settings.dart';
import 'package:archonex_converter/project_files/features/image_converter/domain/models/image_dimension_limit.dart';
import 'package:archonex_converter/project_files/features/image_converter/domain/models/image_format.dart';
import 'package:archonex_converter/project_files/features/image_converter/ui/mappers/image_background_ui.dart';
import 'package:archonex_converter/project_files/features/image_converter/ui/mappers/image_dimension_limit_ui.dart';

/// Manual overrides on top of the quality preset, for the whole batch.
///
/// Only the controls the chosen target can actually use are rendered — a
/// quality dial means nothing to a PNG, and a backdrop means nothing when
/// nothing transparent is being flattened. The same rule prunes the stored
/// settings, so the panel always shows exactly what is in state.
class ImageAdvancedSettingsPanel extends StatelessWidget {
  const ImageAdvancedSettingsPanel({
    required this.target,
    required this.settings,
    required this.showsBackground,
    required this.isEnabled,
    required this.isExpanded,
    required this.onToggle,
    required this.onDimensionChanged,
    required this.onQualityChanged,
    required this.onBackgroundChanged,
    required this.onKeepMetadataChanged,
    required this.onReset,
    super.key,
  });

  static const double _gap = AppSpacing.lg;

  final ImageFormat target;
  final ImageConversionSettings settings;

  /// `true` only when transparency is about to be lost, so the backdrop is a
  /// real decision rather than a knob with no effect.
  final bool showsBackground;

  final bool isEnabled;
  final bool isExpanded;
  final VoidCallback onToggle;
  final ValueChanged<ImageDimensionLimit> onDimensionChanged;
  final ValueChanged<int> onQualityChanged;
  final ValueChanged<ImageBackground> onBackgroundChanged;
  final ValueChanged<bool> onKeepMetadataChanged;
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
      AdvancedSettingRow(
        label: l10n.maxSideLabel,
        child: SettingDropdown<ImageDimensionLimit>(
          value: settings.dimensionLimit,
          options: ImageDimensionLimit.values,
          labelOf: (option) => option.label(context),
          isEnabled: isEnabled,
          onChanged: onDimensionChanged,
        ),
      ),
      const SizedBox(height: _gap),
      if (target.supportsQuality) ...<Widget>[
        AdvancedSettingRow(
          label: l10n.imageQualityLabel,
          child: QualitySlider(
            value: settings.effectiveQuality,
            isEnabled: isEnabled,
            onChanged: onQualityChanged,
          ),
        ),
        const SizedBox(height: _gap),
      ],
      if (showsBackground) ...<Widget>[
        AdvancedSettingRow(
          label: l10n.backgroundLabel,
          child: SettingDropdown<ImageBackground>(
            value: settings.background,
            options: ImageBackground.values,
            labelOf: (option) => option.label(context),
            isEnabled: isEnabled,
            onChanged: onBackgroundChanged,
          ),
        ),
        const SizedBox(height: _gap),
      ],
      SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        value: settings.keepMetadata,
        title: Text(l10n.keepMetadataLabel),
        subtitle: Text(l10n.keepMetadataHint),
        onChanged: isEnabled ? onKeepMetadataChanged : null,
      ),
      const SizedBox(height: _gap),
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
