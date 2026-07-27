import 'package:flutter/material.dart';

/// Dropdown over a fixed list of options.
///
/// Every advanced choice except the quality slider is a bounded enum, so there
/// is nothing to validate: an out of range value cannot be expressed.
class SettingDropdown<T> extends StatelessWidget {
  const SettingDropdown({
    required this.value,
    required this.options,
    required this.labelOf,
    required this.isEnabled,
    required this.onChanged,
    super.key,
  });

  final T value;
  final List<T> options;
  final String Function(T option) labelOf;
  final bool isEnabled;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      // The field keeps its own form state, so a value changed from outside —
      // resetting the advanced panel, for instance — only shows up once the
      // field is rebuilt from scratch.
      key: ValueKey<T>(value),
      initialValue: value,
      isDense: true,
      decoration: const InputDecoration(border: OutlineInputBorder()),
      items: options
          .map(
            (option) => DropdownMenuItem<T>(
              value: option,
              child: Text(labelOf(option)),
            ),
          )
          .toList(),
      onChanged: isEnabled
          ? (selection) {
              if (selection != null) {
                onChanged(selection);
              }
            }
          : null,
    );
  }
}
