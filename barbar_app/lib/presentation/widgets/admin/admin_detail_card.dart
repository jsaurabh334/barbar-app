import 'package:flutter/material.dart';
import 'package:barbar_app/core/theme/app_theme.dart';

class AdminDetailCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Widget? trailing;
  final bool isLoading;

  const AdminDetailCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.trailing,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 4),
                if (isLoading)
                  const SizedBox(width: 80, child: LinearProgressIndicator())
                else
                  Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
