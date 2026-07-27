import 'package:flutter/material.dart';

import 'package:archonex/core/constants/app_durations.dart';
import 'package:archonex/core/constants/app_radius.dart';
import 'package:archonex/core/constants/app_spacing.dart';
import 'package:archonex/l10n/app_localizations.dart';

/// The frame around a converter's advanced controls: a header that expands and
/// collapses, and a slot for whatever fields belong inside.
///
/// It creates none of those fields. Which knobs exist depends entirely on what
/// is being converted, so they arrive through [fields] and this widget stays
/// responsible for nothing but the box and the animation.
class AdvancedSettingsShell extends StatelessWidget {
  const AdvancedSettingsShell({
    required this.isExpanded,
    required this.onToggle,
    required this.fields,
    super.key,
  });

  static const double padding = AppSpacing.lg;
  static const double _collapsedTurns = 0;
  static const double _expandedTurns = 0.5;

  final bool isExpanded;
  final VoidCallback onToggle;
  final List<Widget> fields;

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
              padding: const EdgeInsets.fromLTRB(padding, 0, padding, padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: fields,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.isExpanded, required this.onToggle});

  final bool isExpanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.all(AdvancedSettingsShell.padding),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    l10n.advancedTitle,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.advancedHint,
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
                  ? AdvancedSettingsShell._expandedTurns
                  : AdvancedSettingsShell._collapsedTurns,
              child: const Icon(Icons.expand_more_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
