import 'package:flutter/material.dart';
import 'package:barbar_app/core/theme/app_theme.dart';

class AdminDateRangePicker extends StatelessWidget {
  final String selectedPeriod;
  final ValueChanged<String> onSelected;

  const AdminDateRangePicker({
    super.key,
    required this.selectedPeriod,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final periods = [
      {'value': 'week', 'label': 'Week'},
      {'value': 'month', 'label': 'Month'},
      {'value': 'year', 'label': 'Year'},
    ];

    return Row(
      children: periods.map((p) {
        final isSelected = selectedPeriod == p['value'];
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(p['label']!),
            selected: isSelected,
            selectedColor: AppColors.primary,
            labelStyle: TextStyle(
              color: isSelected ? Colors.black : Colors.white,
              fontSize: 12,
            ),
            onSelected: (_) => onSelected(p['value']!),
          ),
        );
      }).toList(),
    );
  }
}
