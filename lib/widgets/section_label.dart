import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.trailing});

  final String text;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            text.toUpperCase(),
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: AppColors.textFaint),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 6),
            Text(trailing!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.teal)),
          ],
        ],
      ),
    );
  }
}
