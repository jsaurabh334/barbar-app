import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/glass_card.dart';

class BarberNotificationsScreen extends StatelessWidget {
  const BarberNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Sample static notifications — replace with real data when backend supports it
    final notifications = [
      _NotifData(
        icon: LucideIcons.calendarCheck,
        color: AppColors.success,
        title: 'New Booking',
        message: 'Rahul S. booked a Haircut for 10:30 AM today.',
        time: '2 min ago',
      ),
      _NotifData(
        icon: LucideIcons.star,
        color: AppColors.primary,
        title: 'New Review',
        message: 'Priya M. left a ⭐⭐⭐⭐⭐ review on your shop.',
        time: '1 hr ago',
      ),
      _NotifData(
        icon: LucideIcons.home,
        color: AppColors.warning,
        title: 'Home Service Request',
        message: 'Anil K. requested home service at Sector 21.',
        time: '3 hr ago',
      ),
      _NotifData(
        icon: LucideIcons.x,
        color: AppColors.error,
        title: 'Booking Cancelled',
        message: 'Suresh P. cancelled his 11:00 AM appointment.',
        time: 'Yesterday',
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('NOTIFICATIONS'),
      ),
      body: notifications.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.bellOff, size: 56, color: AppColors.textMuted),
                  SizedBox(height: 16),
                  Text('No notifications yet', style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final n = notifications[index];
                return GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: n.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(n.icon, color: n.color, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(n.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                Text(n.time, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(n.message, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _NotifData {
  final IconData icon;
  final Color color;
  final String title;
  final String message;
  final String time;

  _NotifData({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
    required this.time,
  });
}
