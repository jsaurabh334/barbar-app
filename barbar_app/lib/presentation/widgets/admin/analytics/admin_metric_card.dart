import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:barbar_app/core/theme/app_theme.dart';

class AdminMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;
  final String? trend;
  final Color? trendColor;
  final VoidCallback? onTap;

  const AdminMetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color,
    this.trend,
    this.trendColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: c, size: 20),
                const Spacer(),
                if (trend != null)
                  Row(
                    children: [
                      Icon(
                        (trendColor ?? Colors.green) == Colors.green ? LucideIcons.trendingUp : LucideIcons.trendingDown,
                        color: trendColor ?? Colors.green, size: 14,
                      ),
                      const SizedBox(width: 2),
                      Text(trend!, style: TextStyle(color: trendColor ?? Colors.green, fontSize: 11)),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: c)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
