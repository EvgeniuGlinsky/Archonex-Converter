import 'package:flutter/material.dart';

import 'package:archonex_converter/core/constants/app_spacing.dart';
import 'package:archonex_converter/l10n/app_localizations.dart';
import 'package:archonex_converter/project_files/features/converter_shared/ui/widgets/advanced_setting_row.dart';
import 'package:archonex_converter/project_files/features/converter_shared/ui/widgets/advanced_settings_shell.dart';
import 'package:archonex_converter/project_files/features/converter_shared/ui/widgets/quality_slider.dart';
import 'package:archonex_converter/project_files/features/converter_shared/ui/widgets/setting_dropdown.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/domain/models/pdf_conversion_settings.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/domain/models/pdf_page_size.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/domain/models/pdf_target.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/ui/mappers/pdf_page_size_ui.dart';

/// The knobs, filtered down to the ones the current direction can use.
///
/// Page geometry belongs to writing a PDF, resolution and quality to reading
/// one out, and the panel shows only the half that applies — an inert control
/// is worse than an absent one.
class PdfAdvancedSettingsPanel extends StatelessWidget {
  const PdfAdvancedSettingsPanel({
    required this.target,
    required this.settings,
    required this.isEnabled,
    required this.isExpanded,
    required this.onToggle,
    required this.onPageSizeChanged,
    required this.onMarginChanged,
    required this.onRasterDpiChanged,
    required this.onQualityChanged,
    required this.onReset,
    super.key,
  });

  static const double _gap = AppSpacing.lg;

  final PdfTarget target;
  final PdfConversionSettings settings;
  final bool isEnabled;
  final bool isExpanded;
  final VoidCallback onToggle;
  final ValueChanged<PdfPageSize> onPageSizeChanged;
  final ValueChanged<double> onMarginChanged;
  final ValueChanged<int> onRasterDpiChanged;
  final ValueChanged<int> onQualityChanged;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return AdvancedSettingsShell(
      isExpanded: isExpanded,
      onToggle: onToggle,
      fields: <Widget>[
        if (settings.appliesPageSizeFor(target)) ...<Widget>[
          AdvancedSettingRow(
            label: l10n.pageSizeLabel,
            child: SettingDropdown<PdfPageSize>(
              value: settings.pageSize,
              options: PdfPageSize.values,
              labelOf: (size) => size.label(context),
              isEnabled: isEnabled,
              onChanged: onPageSizeChanged,
            ),
          ),
          const SizedBox(height: _gap),
          AdvancedSettingRow(
            label: l10n.marginLabel,
            child: SettingDropdown<PdfMarginOption>(
              value: PdfMarginOption.fromPoints(settings.marginPoints),
              options: PdfMarginOption.values,
              labelOf: (margin) => margin.label(context),
              isEnabled: isEnabled,
              onChanged: (margin) => onMarginChanged(margin.points),
            ),
          ),
        ],
        if (settings.appliesRasterDpiFor(target)) ...<Widget>[
          AdvancedSettingRow(
            label: l10n.resolutionDpiLabel,
            child: SettingDropdown<int>(
              value: settings.rasterDpi,
              options: PdfConversionSettings.rasterDpiOptions,
              labelOf: l10n.dpiValue,
              isEnabled: isEnabled,
              onChanged: onRasterDpiChanged,
            ),
          ),
        ],
        if (settings.appliesQualityFor(target)) ...<Widget>[
          const SizedBox(height: _gap),
          AdvancedSettingRow(
            label: l10n.imageQualityLabel,
            child: QualitySlider(
              value: settings.quality,
              isEnabled: isEnabled,
              onChanged: onQualityChanged,
            ),
          ),
        ],
        const SizedBox(height: _gap),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: isEnabled ? onReset : null,
            icon: const Icon(Icons.restart_alt_rounded),
            label: Text(l10n.resetToPresetLabel),
          ),
        ),
      ],
    );
  }
}
