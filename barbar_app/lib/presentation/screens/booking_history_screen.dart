import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/network/websocket_client.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/booking_model.dart';
import '../bloc/booking/booking_bloc.dart';
import '../bloc/booking/booking_event.dart';
import '../bloc/booking/booking_state.dart';
import '../bloc/check_in/check_in_bloc.dart';
import '../bloc/check_in/check_in_event.dart';
import '../widgets/completion_otp_card.dart';
import 'customer/check_in_screen.dart' show CheckInScreen;
import 'review_screen.dart';

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Map<String, String> _otpByBookingId = {};
  StreamSubscription<Map<String, dynamic>>? _otpSub;

  static const _activeStatuses = ['pending', 'home_service_pending', 'confirmed', 'checked_in', 'waiting', 'next', 'in_progress', 'awaiting_customer_confirmation', 'rescheduled'];
  static const _historyStatuses = ['completed', 'cancelled', 'no_show'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    context.read<BookingBloc>().add(FetchAllBookings());
    _otpSub = context.read<WebSocketClient>().eventsByType('booking_otp_generated').listen((event) {
      if (!mounted) return;
      final payload = event['payload'] is Map ? (event['payload'] as Map) : event;
      final bookingId = payload['booking_id'] as String?;
      final otp = payload['completion_otp'] as String?;
      if (bookingId != null && otp != null) {
        setState(() => _otpByBookingId[bookingId] = otp);
        context.read<BookingBloc>().add(FetchAllBookings());
      }
    });
  }

  @override
  void dispose() {
    _otpSub?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('My Bookings'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: BlocListener<BookingBloc, BookingState>(
        listener: (context, state) {
          if (state is CompletionOtpActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColors.success),
            );
          } else if (state is BookingFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error), backgroundColor: AppColors.error),
            );
          }
        },
        child: BlocBuilder<BookingBloc, BookingState>(
          builder: (context, state) {
            if (state is BookingLoading) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primary));
            } else if (state is BookingFailure) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.alertCircle, size: 48, color: AppColors.error),
                    const SizedBox(height: 12),
                    Text(state.error, style: const TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.read<BookingBloc>().add(FetchAllBookings()),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            } else if (state is BookingsLoaded) {
              final upcoming = state.bookings.where((b) => _activeStatuses.contains(b.status)).toList()
                ..sort((a, b) => a.scheduledStart.compareTo(b.scheduledStart));
              final history = state.bookings.where((b) => _historyStatuses.contains(b.status)).toList()
                ..sort((a, b) => b.scheduledStart.compareTo(a.scheduledStart));

              return TabBarView(
                controller: _tabController,
                children: [
                  _buildUpcomingList(upcoming),
                  _buildHistoryList(history),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildUpcomingList(List<BookingModel> bookings) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.calendarX, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text('No upcoming bookings', style: const TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (context, index) => _buildUpcomingCard(bookings[index]),
    );
  }

  Widget _buildHistoryList(List<BookingModel> bookings) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.calendarX, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text('No booking history', style: const TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (context, index) => _buildHistoryCard(bookings[index]),
    );
  }

  Widget _buildUpcomingCard(BookingModel booking) {
    final statusColor = _statusColor(booking.status);
    final statusLabel = _statusLabel(booking.status);
    final isLate = booking.isLate;
    final hasQueue = booking.queueAssignedAt != null;
    final hasImComing = booking.imComingAt != null;
    
    final bookingDate = DateTime.tryParse(booking.scheduledStart)?.toLocal();
    final now = DateTime.now();
    final isTodayOrPast = bookingDate != null &&
        (bookingDate.year < now.year ||
            (bookingDate.year == now.year && bookingDate.month < now.month) ||
            (bookingDate.year == now.year && bookingDate.month == now.month && bookingDate.day <= now.day));

    return GestureDetector(
      onTap: () => _openCheckIn(booking),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isLate ? AppColors.error.withValues(alpha: 0.4) : AppColors.border,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_statusIcon(booking.status), color: statusColor),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.shopName.isNotEmpty ? booking.shopName : 'Barber Shop',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              _formatDate(booking.scheduledStart),
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatTime(booking.scheduledStart),
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                        if (booking.staff != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            'with ${booking.staff!['name'] ?? ''}',
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              if (hasQueue || hasImComing || isLate) ...[
                const Divider(height: 20, color: AppColors.border),
                if (isLate)
                  Row(
                    children: [
                      const Icon(LucideIcons.alertTriangle, size: 14, color: AppColors.error),
                      const SizedBox(width: 6),
                      Text(
                        _lateMessage(booking),
                        style: const TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                      const Spacer(),
                    ],
                  ),
                if (hasQueue && !isLate)
                  Row(
                    children: [
                      const Icon(LucideIcons.hash, size: 14, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        'Queue #${booking.queuePosition}',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      if (booking.estimatedWaitMinutes > 0) ...[
                        const SizedBox(width: 12),
                        Text(
                          '~${booking.estimatedWaitMinutes} min',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
                      if (booking.status == 'next') ...[
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('NEXT', style: TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.w900)),
                        ),
                      ],
                    ],
                  ),
                if (hasImComing)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.checkCircle, size: 14, color: AppColors.warning),
                        const SizedBox(width: 6),
                        Text(
                          'Shop notified • Grace extended',
                          style: TextStyle(color: AppColors.warning, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  if (booking.status == 'pending' || booking.status == 'home_service_pending')
                    Expanded(
                      child: _miniButton('AWAITING APPROVAL', AppColors.warning, () => _openCheckIn(booking)),
                    ),
                  if (booking.status == 'confirmed' && isTodayOrPast) ...[
                    if (hasQueue)
                      Expanded(
                        child: _miniButton('CHECK IN', AppColors.success, () => _openCheckIn(booking)),
                      ),
                    if (!hasImComing) ...[
                      if (hasQueue) const SizedBox(width: 8),
                      Expanded(
                        child: _miniButton('I\'M COMING', AppColors.warning, () => _imComing(booking)),
                      ),
                    ],
                  ],
                  if (booking.status == 'waiting' || booking.status == 'checked_in')
                    Expanded(
                      child: _miniButton('VIEW QUEUE', AppColors.primary, () => _openCheckIn(booking)),
                    ),
                  if (booking.status == 'next')
                    Expanded(
                      child: _miniButton('GET READY', AppColors.success, () => _openCheckIn(booking)),
                    ),
                  if (booking.status == 'in_progress')
                    Expanded(
                      child: _miniButton('IN PROGRESS', AppColors.info, () => _openCheckIn(booking)),
                    ),
                ],
              ),
              if (booking.isHomeService && booking.status == BookingModel.statusAwaitingCustomerConfirmation) ...[
                const SizedBox(height: 16),
                CompletionOtpCard(booking: booking, otp: _otpByBookingId[booking.id]),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryCard(BookingModel booking) {
    final statusColor = _statusColor(booking.status);
    final statusLabel = _statusLabel(booking.status);

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_statusIcon(booking.status), color: statusColor),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.shopName.isNotEmpty ? booking.shopName : 'Barber Shop',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(_formatDate(booking.scheduledStart),
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          const SizedBox(width: 8),
                          Text(_formatTime(booking.scheduledStart),
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        ],
                      ),
                      if (booking.paymentMethod.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${booking.paymentMethod.toUpperCase()} • ${booking.paymentStatus == 'paid' ? 'Paid' : booking.paymentStatus}',
                          style: TextStyle(fontSize: 11,
                            color: booking.paymentStatus == 'paid' ? AppColors.success : AppColors.textMuted),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(statusLabel,
                    style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ),
        if (booking.status == 'completed' && booking.paymentStatus == 'paid')
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(LucideIcons.star, size: 16),
                label: const Text('Write a Review'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReviewScreen(
                      bookingId: booking.id,
                      shopName: booking.shopName,
                      staffId: booking.staffId,
                      staffName: booking.staff?['name'] as String?,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _openCheckIn(BookingModel booking) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<CheckInBloc>(),
          child: CheckInScreen(bookingId: booking.id),
        ),
      ),
    );
  }

  void _imComing(BookingModel booking) {
    context.read<CheckInBloc>().add(ImComing(booking.id));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notifying the shop...')),
    );
  }

  Widget _miniButton(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(label,
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  String _lateMessage(BookingModel booking) {
    if (booking.graceExtendedUntil != null) {
      final gt = DateTime.tryParse(booking.graceExtendedUntil!);
      if (gt != null) {
        final rem = gt.difference(DateTime.now());
        if (rem.isNegative) return 'Grace period expired. Check in now!';
        return 'Late — grace ends in ${rem.inMinutes} min';
      }
    }
    return 'You\'re late! Please check in.';
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'pending':
      case 'home_service_pending': return LucideIcons.clock;
      case 'confirmed': return LucideIcons.checkCircle;
      case 'checked_in': return LucideIcons.logIn;
      case 'waiting': return LucideIcons.clock;
      case 'next': return LucideIcons.chevronsRight;
      case 'in_progress': return LucideIcons.scissors;
      case 'awaiting_customer_confirmation': return LucideIcons.shieldCheck;
      case 'completed': return LucideIcons.checkCircle;
      case 'cancelled': return LucideIcons.xCircle;
      default: return LucideIcons.clock;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
      case 'home_service_pending': return AppColors.warning;
      case 'confirmed': return AppColors.success;
      case 'checked_in': return AppColors.info;
      case 'waiting': return AppColors.warning;
      case 'next': return AppColors.success;
      case 'in_progress': return AppColors.info;
      case 'awaiting_customer_confirmation': return AppColors.warning;
      case 'completed': return AppColors.success;
      case 'cancelled': return AppColors.error;
      default: return AppColors.textMuted;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending': return 'Requested';
      case 'home_service_pending': return 'Home Pending';
      case 'confirmed': return 'Confirmed';
      case 'checked_in': return 'Checked In';
      case 'waiting': return 'Waiting';
      case 'next': return 'You\'re Next';
      case 'in_progress': return 'In Progress';
      case 'awaiting_customer_confirmation': return 'Confirm Completion';
      case 'completed': return 'Completed';
      case 'cancelled': return 'Cancelled';
      default: return status;
    }
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return iso;
    }
  }

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso);
      final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      return '$h:${dt.minute.toString().padLeft(2, '0')} $ampm';
    } catch (_) {
      return '';
    }
  }
}
