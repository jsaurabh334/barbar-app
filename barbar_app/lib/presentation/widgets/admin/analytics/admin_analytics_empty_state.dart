import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class AdminAnalyticsEmptyState extends StatelessWidget {
  final String message;
  final IconData icon;

  const AdminAnalyticsEmptyState({
    super.key,
    this.message = 'No data available for this period',
    this.icon = LucideIcons.barChart3,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(message, style: const TextStyle(color: Colors.grey), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
