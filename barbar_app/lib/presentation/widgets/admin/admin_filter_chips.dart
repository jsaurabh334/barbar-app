import 'package:flutter/material.dart';
import 'package:barbar_app/core/theme/app_theme.dart';

class AdminFilterChips extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;

  const AdminFilterChips({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: options.map((opt) {
          final isSelected = opt == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(opt),
              selected: isSelected,
              onSelected: (_) => onSelected(isSelected ? '' : opt),
              selectedColor: AppColors.primary.withValues(alpha: 0.2),
              checkmarkColor: AppColors.primary,
              backgroundColor: AppColors.cardBg,
              side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border),
            ),
          );
        }).toList(),
      ),
    );
  }
}
