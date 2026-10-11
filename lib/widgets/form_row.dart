import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The "icon + label above, control below" row used throughout the Setup
/// and Create-club forms.
class FormFieldRow extends StatelessWidget {
  const FormFieldRow({super.key, this.icon, required this.label, required this.child});

  final String? icon;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Text(icon!, style: const TextStyle(fontSize: 19)),
              const SizedBox(width: 8),
            ],
            Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.navy)),
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
