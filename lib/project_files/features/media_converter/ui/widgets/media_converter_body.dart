import 'package:flutter/material.dart';

import 'package:archonex_converter/core/constants/app_file_limits.dart';
import 'package:archonex_converter/core/constants/app_spacing.dart';
import 'package:archonex_converter/l10n/app_localizations.dart';
import 'package:archonex_converter/project_files/features/converter_shared/domain/models/conversion_failure.dart';
import 'package:archonex_converter/project_files/features/converter_shared/ui/widgets/conversion_error_banner.dart';
import 'package:archonex_converter/project_files/features/converter_shared/ui/widgets/conversion_progress_indicator.dart';
import 'package:archonex_converter/project_files/features/converter_shared/ui/widgets/conversion_result_card.dart';
import 'package:archonex_converter/project_files/features/converter_shared/ui/widgets/file_size_limit_notice.dart';
import 'package:archonex_converter/project_files/features/converter_shared/ui/widgets/quality_preset_selector.dart';
import 'package:archonex_converter/project_files/features/media_converter/domain/models/conversion_quality.dart';
import 'package:archonex_converter/project_files/features/media_converter/domain/models/media_format.dart';
import 'package:archonex_converter/project_files/features/media_converter/ui/bloc/media_converter_bloc.dart';
import 'package:archonex_converter/project_files/features/media_converter/ui/mappers/conversion_quality_ui.dart';
import 'package:archonex_converter/project_files/features/media_converter/ui/widgets/advanced_settings_panel.dart';
import 'package:archonex_converter/project_files/features/media_converter/ui/widgets/media_converter_callbacks.dart';
import 'package:archonex_converter/project_files/features/media_converter/ui/widgets/source_file_card.dart';
import 'package:archonex_converter/project_files/features/media_converter/ui/widgets/target_format_grid.dart';

/// Everything between the header and the primary action.
///
/// The screen reveals itself one step at a time: the file first, then what it
/// can become, then how. Nothing below a step exists until that step is done,
/// which is what keeps the target grid honest — it can only be built once the
/// source format is known.
class MediaConverterBody extends StatelessWidget {
  const MediaConverterBody({
    required this.state,
    required this.callbacks,
    super.key,
  });

  static const double _gap = AppSpacing.lg;

  final MediaConverterState state;
  final MediaConverterCallbacks callbacks;

  @override
  Widget build(BuildContext context) {
    final MediaFormat? target = state.target;
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return ListView(
      children: <Widget>[
        FileSizeLimitNotice(
          l10n.maxFileSizeNotice(AppFileLimits.maxUploadLabel),
        ),
        if (!state.isSupported) ...<Widget>[
          const SizedBox(height: _gap),
          const ConversionErrorBanner(
            failure: ConversionUnsupportedFailure(),
          ),
        ],
        const SizedBox(height: _gap),
        SourceFileCard(
          file: state.source,
          isEnabled: state.canPick,
          onPickPressed: callbacks.onPickPressed,
          onRemovePressed: callbacks.onRemovePressed,
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
          QualityPresetSelector<ConversionQuality>(
            options: ConversionQuality.values,
            selected: state.settings.quality,
            labelOf: (quality) => quality.label(context),
            hint: state.settings.quality.hint(context),
            isEnabled: state.canEditSettings,
            onChanged: callbacks.onQualityChanged,
          ),
          const SizedBox(height: _gap),
          AdvancedSettingsPanel(
            target: target,
            settings: state.settings,
            isEnabled: state.canEditSettings,
            isExpanded: state.isAdvancedExpanded,
            onToggle: callbacks.onAdvancedToggled,
            onResolutionChanged: callbacks.onResolutionChanged,
            onFrameRateChanged: callbacks.onFrameRateChanged,
            onVideoQualityChanged: callbacks.onVideoQualityChanged,
            onAudioBitrateChanged: callbacks.onAudioBitrateChanged,
            onKeepAudioChanged: callbacks.onKeepAudioChanged,
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
            label: l10n.convertingLabel,
            progress: state.progress,
            onCancelPressed: callbacks.onCancelPressed,
          ),
        ],
        if (state.result != null) ...<Widget>[
          const SizedBox(height: _gap),
          ConversionResultCard(
            file: state.result!,
            isSaving: state.isSaving,
            onDownloadPressed: callbacks.onDownloadPressed,
          ),
        ],
      ],
    );
  }
}
