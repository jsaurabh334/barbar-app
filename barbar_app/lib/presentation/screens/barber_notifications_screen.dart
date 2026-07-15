import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/notification_model.dart';
import '../bloc/notification/notification_bloc.dart';
import '../bloc/notification/notification_event.dart';
import '../bloc/notification/notification_state.dart';

class BarberNotificationsScreen extends StatefulWidget {
  const BarberNotificationsScreen({super.key});

  @override
  State<BarberNotificationsScreen> createState() => _BarberNotificationsScreenState();
}

class _BarberNotificationsScreenState extends State<BarberNotificationsScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<NotificationBloc>().add(const FetchNotifications(refresh: true));
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      context.read<NotificationBloc>().add(LoadMoreNotifications());
    }
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'booking_confirmed':
      case 'booking_reminder':
        return LucideIcons.calendarCheck;
      case 'booking_modified':
        return LucideIcons.calendar;
      case 'booking_cancelled':
        return LucideIcons.xCircle;
      case 'queue_update':
      case 'wait_time_changed':
        return LucideIcons.clock;
      case 'barber_started':
        return LucideIcons.play;
      case 'barber_completed':
        return LucideIcons.checkCircle;
      case 'review_received':
      case 'review_moderated':
        return LucideIcons.star;
      case 'payment_success':
      case 'refund_completed':
        return LucideIcons.indianRupee;
      case 'payment_failed':
        return LucideIcons.alertTriangle;
      case 'wallet_credit':
        return LucideIcons.arrowUpCircle;
      case 'wallet_debit':
        return LucideIcons.arrowDownCircle;
      case 'new_message':
        return LucideIcons.messageCircle;
      case 'promotion':
      case 'new_offer':
        return LucideIcons.tag;
      case 'system_alert':
        return LucideIcons.shield;
      default:
        return LucideIcons.bell;
    }
  }

  Color _colorForType(String type) {
    if (type.startsWith('booking')) {
      if (type.contains('cancelled')) return AppColors.error;
      if (type.contains('modified')) return AppColors.warning;
      return AppColors.success;
    }
    if (type.startsWith('review')) return AppColors.primary;
    if (type.startsWith('payment') || type.startsWith('refund')) {
      if (type.contains('failed')) return AppColors.error;
      return AppColors.success;
    }
    if (type.startsWith('wallet')) return AppColors.info;
    if (type == 'queue_update' || type == 'wait_time_changed') return AppColors.info;
    if (type == 'promotion' || type == 'new_offer') return AppColors.warning;
    if (type == 'system_alert') return AppColors.error;
    return AppColors.primary;
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  void _onTapNotification(NotificationModel notif) {
    if (!notif.isRead) {
      context.read<NotificationBloc>().add(MarkNotificationRead(notif.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('NOTIFICATIONS'),
        actions: [
          BlocBuilder<NotificationBloc, NotificationState>(
            builder: (context, state) {
              if (state is NotificationLoaded && state.unreadCount > 0) {
                return TextButton(
                  onPressed: () => context.read<NotificationBloc>().add(MarkAllNotificationsRead()),
                  child: const Text('Mark all read'),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocConsumer<NotificationBloc, NotificationState>(
        listener: (context, state) {
          if (state is NotificationError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
            );
          }
        },
        builder: (context, state) {
          if (state is NotificationLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          if (state is NotificationLoaded) {
            if (state.notifications.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.bellOff, size: 64, color: AppColors.textMuted),
                    SizedBox(height: 16),
                    Text('No notifications yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    SizedBox(height: 8),
                    Text('You\'re all caught up!', style: TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<NotificationBloc>().add(const FetchNotifications(refresh: true));
              },
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: state.notifications.length + (state.hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= state.notifications.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    );
                  }

                  final notif = state.notifications[index];
                  return _buildNotificationCard(notif);
                },
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notif) {
    final icon = _iconForType(notif.type);
    final color = _colorForType(notif.type);

    return GestureDetector(
      onTap: () => _onTapNotification(notif),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: notif.isRead ? AppColors.cardBg : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: notif.isRead ? AppColors.border : AppColors.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notif.title,
                          style: TextStyle(
                            fontWeight: notif.isRead ? FontWeight.w500 : FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (!notif.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notif.body,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _timeAgo(notif.createdAt),
                    style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
