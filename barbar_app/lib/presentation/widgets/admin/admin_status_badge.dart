import 'package:flutter/material.dart';
import 'package:barbar_app/core/theme/app_theme.dart';

class AdminStatusBadge extends StatelessWidget {
  final String label;
  final Color? color;
  final double fontSize;

  const AdminStatusBadge({
    super.key,
    required this.label,
    this.color,
    this.fontSize = 11,
  });

  Color _resolveColor() {
    if (color != null) return color!;
    final lower = label.toLowerCase();
    if (lower == 'active' || lower == 'approved' || lower == 'completed' || lower == 'success') return AppColors.success;
    if (lower == 'inactive' || lower == 'rejected' || lower == 'cancelled' || lower == 'failed') return AppColors.error;
    if (lower == 'pending' || lower == 'suspended') return Colors.orange;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final c = _resolveColor();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label.toUpperCase(), style: TextStyle(fontSize: fontSize, color: c, fontWeight: FontWeight.w600)),
    );
  }
}
