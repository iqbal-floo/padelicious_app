import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The backend's player_gender values.
const List<({String value, String label})> genderOptions = [
  (value: 'male', label: 'Male'),
  (value: 'female', label: 'Female'),
  (value: 'other', label: 'Other'),
  (value: 'undisclosed', label: 'Prefer not to say'),
];

/// Segmented gender picker.
///
/// Mixed match formats (Mix Americano, Mixicano) pair one man with one
/// woman, so they need this set — hence [helperText] explaining why.
class GenderSelector extends StatelessWidget {
  const GenderSelector({
    super.key,
    required this.value,
    required this.onChanged,
    this.label = 'Gender',
    this.helperText,
    this.errorText,
  });

  final String? value;
  final ValueChanged<String?> onChanged;
  final String label;
  final String? helperText;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.navy,
            ),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: genderOptions.map((option) {
            final selected = value == option.value;
            return GestureDetector(
              onTap: () => onChanged(selected ? null : option.value),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: selected ? AppColors.navy : AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: selected ? AppColors.navy : AppColors.border,
                  ),
                ),
                child: Text(
                  option.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : AppColors.navy,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              errorText!,
              style: const TextStyle(fontSize: 11, color: AppColors.error),
            ),
          )
        else if (helperText != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              helperText!,
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ),
      ],
    );
  }
}
