import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../bloc/booking/booking_bloc.dart';
import '../bloc/booking/booking_event.dart';
import '../bloc/booking/booking_state.dart';
import '../widgets/glass_card.dart';
import '../../data/models/booking_model.dart';

class BarberHomeServiceScreen extends StatefulWidget {
  const BarberHomeServiceScreen({super.key});

  @override
  State<BarberHomeServiceScreen> createState() => _BarberHomeServiceScreenState();
}

class _BarberHomeServiceScreenState extends State<BarberHomeServiceScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    context.read<BookingBloc>().add(FetchHomeServiceRequests());
  }

  void _showRejectDialog(String bookingId) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Reject Request'),
          content: TextField(
            controller: reasonController,
            decoration: const InputDecoration(labelText: 'Reason for rejection', hintText: 'e.g., Too far, fully booked'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () {
                if (reasonController.text.trim().isEmpty) return;
                context.read<BookingBloc>().add(RejectHomeServiceRequest(bookingId: bookingId, reason: reasonController.text));
                Navigator.pop(context);
              },
              child: const Text('Reject', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRequestCard(BookingModel booking, {bool showActions = false}) {
    final scheduledStart = DateTime.parse(booking.scheduledStart);
    return GlassCard(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                booking.customer?['full_name'] ?? 'Unknown Customer',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('₹${booking.finalPrice}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(LucideIcons.calendar, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Text(DateFormat('MMM dd, yyyy • hh:mm a').format(scheduledStart), style: const TextStyle(color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(LucideIcons.mapPin, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${booking.travelDistanceKm.toStringAsFixed(1)} km away • Est. Travel: ${booking.travelTimeMin} min',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          if (booking.customerNotes != null && booking.customerNotes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(LucideIcons.messageSquare, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(child: Text(booking.customerNotes!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
                ],
              ),
            ),
          ],
          if (showActions) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showRejectDialog(booking.id),
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error)),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      context.read<BookingBloc>().add(AcceptHomeServiceRequest(booking.id));
                    },
                    child: const Text('Accept'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HOME SERVICE REQUESTS'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Accepted'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: BlocConsumer<BookingBloc, BookingState>(
        listener: (context, state) {
          if (state is BookingFailure) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error), backgroundColor: AppColors.error));
          }
        },
        builder: (context, state) {
          if (state is BookingLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is BookingsLoaded) {
            final pending = state.bookings.where((b) => b.status == 'home_service_pending').toList();
            final accepted = state.bookings.where((b) => b.status == 'confirmed' || b.status == 'in_progress').toList();
            final completed = state.bookings.where((b) => b.status == 'completed' || b.status == 'cancelled' || b.status == 'no_show').toList();

            return TabBarView(
              controller: _tabController,
              children: [
                _buildList(pending, showActions: true, emptyMsg: 'No pending requests'),
                _buildList(accepted, showActions: false, emptyMsg: 'No accepted requests'),
                _buildList(completed, showActions: false, emptyMsg: 'No past requests'),
              ],
            );
          }
          return const Center(child: Text('Failed to load requests'));
        },
      ),
    );
  }

  Widget _buildList(List<BookingModel> list, {required bool showActions, required String emptyMsg}) {
    if (list.isEmpty) {
      return Center(child: Text(emptyMsg));
    }
    return RefreshIndicator(
      onRefresh: () async => context.read<BookingBloc>().add(FetchHomeServiceRequests()),
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: list.length,
        itemBuilder: (context, index) => _buildRequestCard(list[index], showActions: showActions),
      ),
    );
  }
}
