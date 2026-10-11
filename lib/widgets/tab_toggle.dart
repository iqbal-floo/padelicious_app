import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class TabToggle extends StatelessWidget {
  const TabToggle({super.key, required this.labels, required this.selectedIndex, required this.onSelect});

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(9),
                onTap: () => onSelect(i),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: i == selectedIndex ? Colors.white : null,
                    borderRadius: BorderRadius.circular(9),
                    boxShadow: i == selectedIndex
                        ? [BoxShadow(color: AppColors.navy.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 1))]
                        : null,
                  ),
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: i == selectedIndex ? FontWeight.w800 : FontWeight.w700,
                      color: i == selectedIndex ? AppColors.navy : AppColors.textMuted,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
