import 'package:flutter/material.dart';

import 'package:archonex_converter/core/constants/app_spacing.dart';
import 'package:archonex_converter/l10n/app_localizations.dart';
import 'package:archonex_converter/project_files/features/converter_shared/domain/models/conversion_failure.dart';
import 'package:archonex_converter/project_files/features/converter_shared/ui/mappers/converter_limits_ui.dart';
import 'package:archonex_converter/project_files/features/converter_shared/ui/widgets/conversion_error_banner.dart';
import 'package:archonex_converter/project_files/features/converter_shared/ui/widgets/conversion_progress_indicator.dart';
import 'package:archonex_converter/project_files/features/converter_shared/ui/widgets/file_size_limit_notice.dart';
import 'package:archonex_converter/project_files/features/converter_shared/ui/widgets/quality_preset_selector.dart';
import 'package:archonex_converter/project_files/features/image_converter/domain/models/image_format.dart';
import 'package:archonex_converter/project_files/features/image_converter/domain/models/image_quality.dart';
import 'package:archonex_converter/project_files/features/image_converter/ui/bloc/image_converter_bloc.dart';
import 'package:archonex_converter/project_files/features/image_converter/ui/mappers/image_quality_ui.dart';
import 'package:archonex_converter/project_files/features/image_converter/ui/widgets/batch_results_card.dart';
import 'package:archonex_converter/project_files/features/image_converter/ui/widgets/image_advanced_settings_panel.dart';
import 'package:archonex_converter/project_files/features/image_converter/ui/widgets/image_converter_callbacks.dart';
import 'package:archonex_converter/project_files/features/image_converter/ui/widgets/source_image_list.dart';
import 'package:archonex_converter/project_files/features/image_converter/ui/widgets/target_format_grid.dart';
import 'package:archonex_converter/project_files/features/usage_quota/ui/widgets/quota_notice.dart';

/// Everything between the header and the primary action.
///
/// The screen reveals itself one step at a time: the photos first, then what
/// they can become, then how. Nothing below a step exists until that step is
/// done, which is what keeps the target grid honest — it can only be built once
/// the batch is known.
class ImageConverterBody extends StatelessWidget {
  const ImageConverterBody({
    required this.state,
    required this.callbacks,
    super.key,
  });

  static const double _gap = AppSpacing.lg;

  final ImageConverterState state;
  final ImageConverterCallbacks callbacks;

  @override
  Widget build(BuildContext context) {
    final ImageFormat? target = state.target;
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final String? limits = ConverterLimitsUi.forImages(context);

    return ListView(
      children: <Widget>[
        if (limits != null) FileSizeLimitNotice(limits),
        QuotaNotice(
          allowance: state.allowance,
          onUpgradePressed: callbacks.onUpgradePressed,
        ),
        if (!state.isSupported) ...<Widget>[
          const SizedBox(height: _gap),
          const ConversionErrorBanner(
            failure: ConversionUnsupportedFailure(),
          ),
        ],
        const SizedBox(height: _gap),
        SourceImageList(
          items: state.items,
          totalBytes: state.totalSourceBytes,
          canPick: state.canPick,
          canEdit: state.canEditSettings,
          canSave: !state.isSaving,
          onPickPressed: callbacks.onPickPressed,
          onClearPressed: callbacks.onClearPressed,
          onRemovePressed: callbacks.onRemovePressed,
          onSavePressed: callbacks.onSavePressed,
        ),
        if (state.availableTargets.isNotEmpty) ...<Widget>[
          const SizedBox(height: _gap),
          TargetFormatGrid(
            targets: state.availableTargets,
            selected: target,
            isEnabled: state.canEditSettings,
            onSelected: callbacks.onTargetSelected,
          ),
        ],
        if (target != null) ...<Widget>[
          const SizedBox(height: _gap),
          QualityPresetSelector<ImageQuality>(
            options: ImageQuality.values,
            selected: state.settings.quality,
            labelOf: (quality) => quality.label(context),
            hint: state.settings.quality.hint(context),
            isEnabled: state.canEditSettings,
            onChanged: callbacks.onQualityChanged,
          ),
          const SizedBox(height: _gap),
          ImageAdvancedSettingsPanel(
            target: target,
            settings: state.settings,
            showsBackground: state.needsBackgroundChoice,
            isEnabled: state.canEditSettings,
            isExpanded: state.isAdvancedExpanded,
            onToggle: callbacks.onAdvancedToggled,
            onDimensionChanged: callbacks.onDimensionChanged,
            onQualityChanged: callbacks.onImageQualityChanged,
            onBackgroundChanged: callbacks.onBackgroundChanged,
            onKeepMetadataChanged: callbacks.onKeepMetadataChanged,
            onReset: callbacks.onAdvancedReset,
          ),
        ],
        if (state.failure != null) ...<Widget>[
          const SizedBox(height: _gap),
          ConversionErrorBanner(failure: state.failure!),
        ],
        if (state.isConverting) ...<Widget>[
          const SizedBox(height: _gap),
          ConversionProgressIndicator(
            // The photo being worked on is the one after the last finished
            // one, except at the very end, where nothing is left to start.
            label: l10n.convertingCount(
              (state.finishedCount + 1).clamp(1, state.totalCount),
              state.totalCount,
            ),
            progress: state.progress,
            onCancelPressed: callbacks.onCancelPressed,
          ),
        ],
        if (state.hasResults && !state.isConverting) ...<Widget>[
          const SizedBox(height: _gap),
          BatchResultsCard(
            convertedCount: state.convertedCount,
            totalCount: state.totalCount,
            totalBytes: state.totalResultBytes,
            isSaving: state.isSaving,
            onSaveAllPressed: callbacks.onSaveAllPressed,
          ),
        ],
      ],
    );
  }
}
