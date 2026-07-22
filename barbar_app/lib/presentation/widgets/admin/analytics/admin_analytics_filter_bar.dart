import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:barbar_app/core/theme/app_theme.dart';

class AdminAnalyticsFilterBar extends StatelessWidget {
  final String selectedPeriod;
  final ValueChanged<String> onPeriodChanged;
  final VoidCallback? onExport;

  const AdminAnalyticsFilterBar({
    super.key,
    required this.selectedPeriod,
    required this.onPeriodChanged,
    this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    final periods = ['week', 'month', 'year'];
    final labels = ['Week', 'Month', 'Year'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          ...List.generate(periods.length, (i) {
            final isSelected = selectedPeriod == periods[i];
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(labels[i], style: const TextStyle(fontSize: 12)),
                selected: isSelected,
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(color: isSelected ? Colors.black : Colors.white),
                onSelected: (_) => onPeriodChanged(periods[i]),
              ),
            );
          }),
          const Spacer(),
          if (onExport != null)
            IconButton(
              icon: const Icon(LucideIcons.download, size: 20),
              onPressed: onExport,
              tooltip: 'Export CSV',
            ),
        ],
      ),
    );
  }
}
