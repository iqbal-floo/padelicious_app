import 'package:flutter/material.dart';

import '../models/match_config.dart';
import '../theme/app_colors.dart';

/// A `DropdownButtonFormField` styled to match the design's `<select>`
/// fields, with an optional flat option list or grouped-with-headers list
/// (mirrors the `<optgroup>` match-type picker).
class SimpleDropdown extends StatelessWidget {
  const SimpleDropdown({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String value;
  final List<MatchTypeOption> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return _styledDropdown(
      value: value,
      items: [for (final o in options) DropdownMenuItem(value: o.value, child: Text(o.label))],
      onChanged: onChanged,
    );
  }
}

class GroupedDropdown extends StatelessWidget {
  const GroupedDropdown({
    super.key,
    required this.value,
    required this.groups,
    required this.onChanged,
  });

  final String value;
  final List<MatchTypeGroup> groups;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final items = <DropdownMenuItem<String>>[];
    for (final group in groups) {
      items.add(DropdownMenuItem(
        enabled: false,
        value: '__group_${group.category}',
        child: Text(group.category, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textFaint)),
      ));
      for (final option in group.options) {
        items.add(DropdownMenuItem(
          value: option.value,
          child: Padding(padding: const EdgeInsets.only(left: 8), child: Text(option.label)),
        ));
      }
    }
    return _styledDropdown(value: value, items: items, onChanged: onChanged);
  }
}

Widget _styledDropdown({
  required String value,
  required List<DropdownMenuItem<String>> items,
  required ValueChanged<String> onChanged,
}) {
  return DropdownButtonFormField<String>(
    value: value,
    isExpanded: true,
    icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textMuted, size: 18),
    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.navy),
    decoration: const InputDecoration(
      fillColor: AppColors.surfaceAlt,
      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    ),
    items: items,
    onChanged: (v) {
      if (v != null) onChanged(v);
    },
  );
}
