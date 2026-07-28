import 'package:flutter/material.dart';

import 'package:archonex_converter/core/constants/app_spacing.dart';
import 'package:archonex_converter/l10n/app_localizations.dart';
import 'package:archonex_converter/project_files/features/converter_shared/ui/widgets/section_title.dart';

/// Where a key bought on the website is pasted.
///
/// Stateful only to own its `TextEditingController`; the value itself lives in
/// the bloc, like every other piece of screen state.
class LicenseKeyField extends StatefulWidget {
  const LicenseKeyField({
    required this.value,
    required this.isEnabled,
    required this.onChanged,
    required this.onSubmitted,
    super.key,
  });

  final String value;
  final bool isEnabled;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmitted;

  @override
  State<LicenseKeyField> createState() => _LicenseKeyFieldState();
}

class _LicenseKeyFieldState extends State<LicenseKeyField> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.value);

  @override
  void didUpdateWidget(LicenseKeyField oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Only when the bloc holds something the field does not — a redemption
    // clearing the box, say. Assigning on every rebuild would fight the cursor.
    if (widget.value != _controller.text) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SectionTitle(l10n.paywallLicenseKeyTitle),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _controller,
          enabled: widget.isEnabled,
          autocorrect: false,
          enableSuggestions: false,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            labelText: l10n.paywallLicenseKeyLabel,
            helperText: l10n.paywallLicenseKeyHint,
            border: const OutlineInputBorder(),
          ),
          onChanged: widget.onChanged,
          onSubmitted: (_) => widget.onSubmitted(),
        ),
      ],
    );
  }
}
