import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class LabeledField extends StatelessWidget {
  const LabeledField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.errorText,
    this.topSpacing = 16,
    this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? errorText;
  final double topSpacing;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: topSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.navy)),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            onChanged: onChanged,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.navy),
            decoration: InputDecoration(
              hintText: hint,
              fillColor: Colors.white,
              enabledBorder: OutlineInputBorder(
                borderRadius: const BorderRadius.all(Radius.circular(10)),
                borderSide: BorderSide(color: errorText != null ? AppColors.error : AppColors.border, width: 1.5),
              ),
            ),
          ),
          if (errorText != null) ...[
            const SizedBox(height: 4),
            Text(errorText!, style: const TextStyle(fontSize: 12, color: AppColors.error, fontWeight: FontWeight.w600)),
          ],
        ],
      ),
    );
  }
}
