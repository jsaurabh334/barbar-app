import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_theme.dart';
import '../bloc/booking/booking_bloc.dart';
import '../bloc/booking/booking_state.dart';
import '../../../data/models/booking_model.dart';
import '../widgets/glass_card.dart';

class BarberBookingsScreen extends StatefulWidget {
  const BarberBookingsScreen({super.key});

  @override
  State<BarberBookingsScreen> createState() => _BarberBookingsScreenState();
}

class _BarberBookingsScreenState extends State<BarberBookingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
        title: const Text('BOOKINGS'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: "Today's"),
            Tab(text: "Upcoming"),
            Tab(text: "Completed"),
            Tab(text: "Cancelled"),
          ],
        ),
      ),
      body: BlocBuilder<BookingBloc, BookingState>(
        builder: (context, state) {
          if (state is BookingLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (state is BookingsLoaded) {
            final now = DateTime.now();
            final todayBookings = state.bookings.where((b) {
              final d = DateTime.tryParse(b.scheduledStart);
              return d != null && d.year == now.year && d.month == now.month && d.day == now.day && b.status != 'completed' && b.status != 'cancelled';
            }).toList();

            final upcomingBookings = state.bookings.where((b) {
              final d = DateTime.tryParse(b.scheduledStart);
              return d != null && d.isAfter(DateTime(now.year, now.month, now.day, 23, 59)) && b.status != 'completed' && b.status != 'cancelled';
            }).toList();

            final completedBookings = state.bookings.where((b) => b.status == 'completed').toList();
            final cancelledBookings = state.bookings.where((b) => b.status == 'cancelled').toList();

            return TabBarView(
              controller: _tabController,
              children: [
                _buildList(todayBookings),
                _buildList(upcomingBookings),
                _buildList(completedBookings),
                _buildList(cancelledBookings),
              ],
            );
          }
          return const Center(child: Text('No bookings available'));
        },
      ),
    );
  }

  Widget _buildList(List<BookingModel> list) {
    if (list.isEmpty) {
      return const Center(child: Text('No bookings found', style: TextStyle(color: AppColors.textSecondary)));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final booking = list[index];
        final isCompleted = booking.status == 'completed';
        final isCancelled = booking.status == 'cancelled';
        final statusColor = isCompleted ? AppColors.success : (isCancelled ? AppColors.error : AppColors.info);

        return GlassCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.surface,
                child: const Icon(LucideIcons.user, color: AppColors.textSecondary, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(booking.customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(
                      booking.services.map((s) => s.name).join(', '),
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    booking.scheduledStart.split('T').last.substring(0, 5),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      booking.status.toUpperCase(),
                      style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
