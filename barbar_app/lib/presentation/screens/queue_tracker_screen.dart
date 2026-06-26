import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/network/websocket_client.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/booking_model.dart';
import '../bloc/booking/booking_bloc.dart';
import '../bloc/booking/booking_event.dart';
import '../bloc/booking/booking_state.dart';
import '../widgets/glass_card.dart';

class QueueTrackerScreen extends StatefulWidget {
  final WebSocketClient webSocketClient;

  const QueueTrackerScreen({super.key, required this.webSocketClient});

  @override
  State<QueueTrackerScreen> createState() => _QueueTrackerScreenState();
}

class _QueueTrackerScreenState extends State<QueueTrackerScreen> with SingleTickerProviderStateMixin {
  late AnimationController _radialController;
  BookingModel? _activeBooking;

  @override
  void initState() {
    super.initState();
    _radialController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // Initial load
    context.read<BookingBloc>().add(FetchAllBookings());

    // Listen to real-time websocket updates
    widget.webSocketClient.events.listen((event) {
      if (!mounted) return;
      if (event['type'] == 'queue_update') {
        final payload = event['payload'] as Map<String, dynamic>;
        final position = payload['current_position'] as int;
        final waitMin = (payload['estimated_wait_min'] as num).toInt();
        
        context.read<BookingBloc>().add(
          StreamQueuePositionUpdate(
            newPosition: position,
            estimatedWaitMin: waitMin,
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _radialController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LIVE QUEUE TRACKER'),
      ),
      body: BlocConsumer<BookingBloc, BookingState>(
        listener: (context, state) {
          if (state is BookingsLoaded) {
            final active = state.bookings.firstWhere(
              (b) => b.status == 'pending' || b.status == 'confirmed' || b.status == 'in_progress',
              orElse: () => state.bookings.first,
            );
            setState(() {
              _activeBooking = active;
            });
          }
        },
        builder: (context, state) {
          if (state is BookingLoading && _activeBooking == null) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          if (_activeBooking == null) {
            return _buildEmptyState();
          }

          // Fetch parameters based on state mapping
          int pos = _activeBooking!.queuePosition;
          int wait = _activeBooking!.estimatedWaitMinutes;
          int ahead = pos > 1 ? pos - 1 : 0;
          String status = _activeBooking!.status;

          if (state is QueuePositionLoaded) {
            pos = state.currentPosition;
            ahead = state.peopleAhead;
            wait = state.estimatedWaitMin;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                
                // Pulsing Ring visualization
                Center(child: _buildRadialTracker(pos, ahead, status)),
                const SizedBox(height: 32),

                // Wait Info Glass Card
                _buildDetailsCard(wait, ahead, status),
                const SizedBox(height: 24),

                // Selected services summary list
                _buildServicesCard(),
                const SizedBox(height: 32),

                // Cancel booking option
                if (status == 'pending' || status == 'confirmed')
                  TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: AppColors.error),
                    onPressed: _cancelBooking,
                    icon: const Icon(LucideIcons.xCircle, size: 18),
                    label: const Text('CANCEL APPOINTMENT & LEAVE LINE', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRadialTracker(int pos, int ahead, String status) {
    String message = 'Waiting';
    if (status == 'in_progress') {
      message = 'STYLING NOW';
    } else if (pos == 1) {
      message = 'YOU ARE NEXT';
    }

    return AnimatedBuilder(
      animation: _radialController,
      builder: (context, child) {
        return Container(
          width: 220,
          height: 220,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surface,
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.1 + (_radialController.value * 0.15)),
              width: 12,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.08 + (_radialController.value * 0.05)),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  message,
                  style: const TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold, letterSpacing: 2),
                ),
                const SizedBox(height: 8),
                Text(
                  '#$pos',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontSize: 72,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$ahead CLIENTS AHEAD',
                  style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailsCard(int wait, int ahead, String status) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      opacity: 0.1,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ESTIMATED DELAY', style: TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  '~$wait MINS',
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 22),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 40, color: AppColors.border),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('STATUS INDEX', style: TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  status.toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'ACTIVE BOOKING SERVICES',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
          ),
          const Divider(height: 24, color: AppColors.border),
          ..._activeBooking!.services.map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('₹${s.price.toInt()}', style: const TextStyle(color: AppColors.primary)),
              ],
            ),
          )),
          const Divider(height: 24, color: AppColors.border),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Charges:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('₹${_activeBooking!.finalPrice.toInt()}', style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primary, fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.users, size: 64, color: AppColors.textMuted),
          SizedBox(height: 16),
          Text(
            'No Active Queue Placements',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          SizedBox(height: 8),
          Text(
            'Explore near salons on the home screen to book slots.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  void _cancelBooking() {
    context.read<BookingBloc>().add(
      UpdateBookingStatus(bookingId: _activeBooking!.id, status: 'cancelled'),
    );
  }
}
