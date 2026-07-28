import 'package:flutter/material.dart';

import 'package:archonex_converter/core/constants/app_file_limits.dart';
import 'package:archonex_converter/core/constants/app_spacing.dart';
import 'package:archonex_converter/l10n/app_localizations.dart';
import 'package:archonex_converter/project_files/features/converter_shared/domain/models/conversion_failure.dart';
import 'package:archonex_converter/project_files/features/converter_shared/ui/widgets/conversion_error_banner.dart';
import 'package:archonex_converter/project_files/features/converter_shared/ui/widgets/conversion_progress_indicator.dart';
import 'package:archonex_converter/project_files/features/converter_shared/ui/widgets/file_size_limit_notice.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/domain/models/pdf_target.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/ui/bloc/pdf_converter_bloc.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/ui/widgets/pdf_advanced_settings_panel.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/ui/widgets/pdf_converter_callbacks.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/ui/widgets/pdf_results_card.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/ui/widgets/pdf_target_grid.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/ui/widgets/source_document_list.dart';
import 'package:archonex_converter/project_files/features/usage_quota/ui/widgets/quota_notice.dart';

/// Everything between the header and the primary action.
///
/// Reveals itself a step at a time, the same way the image converter does: the
/// files first, then what they can become, then how. The target grid can only
/// be built once the selection is known, because the selection is what decides
/// the direction.
class PdfConverterBody extends StatelessWidget {
  const PdfConverterBody({
    required this.state,
    required this.callbacks,
    super.key,
  });

  static const double _gap = AppSpacing.lg;

  final PdfConverterState state;
  final PdfConverterCallbacks callbacks;

  @override
  Widget build(BuildContext context) {
    final PdfTarget? target = state.target;
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return ListView(
      children: <Widget>[
        FileSizeLimitNotice(
          l10n.pdfSourcesNotice(
            AppFileLimits.maxBatchFiles,
            AppFileLimits.maxUploadLabel,
          ),
        ),
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
        SourceDocumentList(
          sources: state.sources,
          totalBytes: state.totalSourceBytes,
          canPick: state.canPick,
          canEdit: state.canEditSettings,
          onPickPressed: callbacks.onPickPressed,
          onClearPressed: callbacks.onClearPressed,
          onRemovePressed: callbacks.onRemovePressed,
        ),
        if (state.availableTargets.isNotEmpty) ...<Widget>[
          const SizedBox(height: _gap),
          PdfTargetGrid(
            targets: state.availableTargets,
            selected: target,
            isEnabled: state.canEditSettings,
            onSelected: callbacks.onTargetSelected,
          ),
        ],
        if (target != null && state.hasAdvancedSettings) ...<Widget>[
          const SizedBox(height: _gap),
          PdfAdvancedSettingsPanel(
            target: target,
            settings: state.settings,
            isEnabled: state.canEditSettings,
            isExpanded: state.isAdvancedExpanded,
            onToggle: callbacks.onAdvancedToggled,
            onPageSizeChanged: callbacks.onPageSizeChanged,
            onMarginChanged: callbacks.onMarginChanged,
            onRasterDpiChanged: callbacks.onRasterDpiChanged,
            onQualityChanged: callbacks.onQualityChanged,
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
            // The page being worked on is the one after the last finished one,
            // except at the very end, where nothing is left to start.
            label: l10n.convertingPages(
              (state.pagesDone + 1).clamp(1, _atLeastOne(state.pagesTotal)),
              _atLeastOne(state.pagesTotal),
            ),
            progress: state.progress,
            onCancelPressed: callbacks.onCancelPressed,
          ),
        ],
        if (state.hasResults && !state.isConverting) ...<Widget>[
          const SizedBox(height: _gap),
          PdfResultsCard(
            results: state.results,
            isSaving: state.isSaving,
            onSavePressed: callbacks.onSavePressed,
            onSaveAllPressed: callbacks.onSaveAllPressed,
          ),
        ],
      ],
    );
  }

  /// The total is zero until the engine has counted the pages, and "page 1 of
  /// 0" reads as a bug rather than as a pending count.
  static int _atLeastOne(int total) => total == 0 ? 1 : total;
}
