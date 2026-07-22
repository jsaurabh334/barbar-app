import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/booking_model.dart';
import '../bloc/booking/booking_bloc.dart';
import '../bloc/booking/booking_event.dart';
import '../bloc/booking/booking_state.dart';
import 'review_screen.dart';

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    context.read<BookingBloc>().add(FetchAllBookings());
  }

  @override
  void dispose() {
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
      body: BlocBuilder<BookingBloc, BookingState>(
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
            final upcoming = state.bookings.where((b) =>
              b.status == 'pending' || b.status == 'confirmed' || b.status == 'in_progress' || b.status == 'home_service_pending'
            ).toList();
            final history = state.bookings.where((b) =>
              b.status == 'completed' || b.status == 'cancelled' || b.status == 'no_show'
            ).toList();

            return TabBarView(
              controller: _tabController,
              children: [
                _buildList(upcoming, 'No upcoming bookings'),
                _buildList(history, 'No booking history'),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildList(List<BookingModel> bookings, String emptyText) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.calendarX, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(emptyText, style: const TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (context, index) => _buildBookingCard(bookings[index]),
    );
  }

  Widget _buildBookingCard(BookingModel booking) {
    final isUpcoming = booking.status == 'pending' || booking.status == 'confirmed' || booking.status == 'in_progress';
    final statusColor = switch (booking.status) {
      'pending' => AppColors.warning,
      'confirmed' => AppColors.primary,
      'in_progress' => AppColors.info,
      'completed' => AppColors.success,
      'cancelled' => AppColors.error,
      _ => AppColors.textMuted,
    };
    final statusLabel = switch (booking.status) {
      'pending' => 'Pending',
      'confirmed' => 'Confirmed',
      'in_progress' => 'In Progress',
      'completed' => 'Completed',
      'cancelled' => 'Cancelled',
      _ => booking.status,
    };

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
                    child: Icon(
                      switch (booking.status) {
                        'completed' => LucideIcons.checkCircle,
                        'cancelled' => LucideIcons.xCircle,
                        'in_progress' => LucideIcons.loader,
                        _ => LucideIcons.clock,
                      },
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.customerName,
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
                        if (isUpcoming && booking.queuePosition > 0) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Queue #${booking.queuePosition} • Est. ${booking.estimatedWaitMinutes} min',
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                          ),
                        ],
                        if (booking.paymentMethod.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${booking.paymentMethod.toUpperCase()} • ${booking.paymentStatus == 'paid' ? 'Paid' : booking.paymentStatus == 'initiated' ? 'Processing' : 'Pending'}',
                            style: TextStyle(
                              fontSize: 11,
                              color: booking.paymentStatus == 'paid' ? AppColors.success : AppColors.textMuted,
                            ),
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
