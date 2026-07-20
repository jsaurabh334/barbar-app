import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/tracking/tracking_response.dart';

class TimelineWidget extends StatelessWidget {
  final List<TimelineEntry> entries;
  final String currentStatus;

  const TimelineWidget({
    super.key,
    required this.entries,
    required this.currentStatus,
  });

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();

    final uniqueEntries = _deduplicate(entries);
    final currentIndex = uniqueEntries.indexWhere(
      (e) => e.status == currentStatus,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(LucideIcons.listChecks, size: 18, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Timeline', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ]),
          const SizedBox(height: 16),
          ...List.generate(uniqueEntries.length, (i) {
            final entry = uniqueEntries[i];
            final isCompleted = i <= currentIndex;
            final isCurrent = i == currentIndex;

            return _buildTimelineItem(
              entry: entry,
              isCompleted: isCompleted,
              isCurrent: isCurrent,
              isLast: i == uniqueEntries.length - 1,
            );
          }),
        ],
      ),
    );
  }

  List<TimelineEntry> _deduplicate(List<TimelineEntry> entries) {
    final seen = <String>{};
    final result = <TimelineEntry>[];
    for (final e in entries) {
      if (seen.add(e.status)) {
        result.add(e);
      }
    }
    return result;
  }

  Widget _buildTimelineItem({
    required TimelineEntry entry,
    required bool isCompleted,
    required bool isCurrent,
    required bool isLast,
  }) {
    final label = _statusLabel(entry.status);
    final time = _formatTime(entry.timestamp);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: isCurrent ? 14 : 10,
                  height: isCurrent ? 14 : 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted ? AppColors.success : AppColors.textMuted,
                    border: isCurrent
                        ? Border.all(color: AppColors.primary, width: 3)
                        : null,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isCompleted ? AppColors.success : AppColors.border,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                    color: isCompleted ? AppColors.textPrimary : AppColors.textMuted,
                  ),
                ),
                if (entry.note.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      entry.note,
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ),
                Text(
                  time,
                  style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending': return 'Order Placed';
      case 'accepted': return 'Order Accepted';
      case 'packed': return 'Packed';
      case 'ready_for_pickup': return 'Ready for Pickup';
      case 'driver_assigned': return 'Driver Assigned';
      case 'driver_accepted': return 'Driver Accepted';
      case 'picked_up': return 'Picked Up';
      case 'out_for_delivery': return 'Out for Delivery';
      case 'delivered': return 'Delivered';
      case 'cancelled': return 'Cancelled';
      default: return status.replaceAll('_', ' ').toUpperCase();
    }
  }

  String _formatTime(String timestamp) {
    try {
      final dt = DateTime.parse(timestamp);
      final hour = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      return '$hour:$min';
    } catch (_) {
      return '';
    }
  }
}
