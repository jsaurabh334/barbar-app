import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/network/websocket_client.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/booking_model.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_event.dart';
import '../bloc/booking/booking_bloc.dart';
import '../bloc/booking/booking_event.dart';
import '../bloc/booking/booking_state.dart';
import '../widgets/glass_card.dart';

class BarberDashboardScreen extends StatefulWidget {
  final WebSocketClient webSocketClient;

  const BarberDashboardScreen({super.key, required this.webSocketClient});

  @override
  State<BarberDashboardScreen> createState() => _BarberDashboardScreenState();
}

class _BarberDashboardScreenState extends State<BarberDashboardScreen> {
  int _selectedTab = 0;
  String _startTime = '09:00';
  String _endTime = '21:00';

  @override
  void initState() {
    super.initState();
    context.read<BookingBloc>().add(FetchAllBookings());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BARBER CONSOLE'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.logOut),
            onPressed: () => context.read<AuthBloc>().add(LogoutRequested()),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTab,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        backgroundColor: AppColors.surface,
        onTap: (index) {
          setState(() {
            _selectedTab = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(LucideIcons.listOrdered), label: 'Active Queues'),
          BottomNavigationBarItem(icon: Icon(LucideIcons.calendar), label: 'Schedule Hours'),
        ],
      ),
      body: _selectedTab == 0 ? _buildActiveQueuesTab() : _buildScheduleTab(),
    );
  }

  Widget _buildActiveQueuesTab() {
    return BlocBuilder<BookingBloc, BookingState>(
      builder: (context, state) {
        if (state is BookingLoading) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        } else if (state is BookingsLoaded) {
          final bookings = state.bookings;
          if (bookings.isEmpty) {
            return const Center(child: Text('No client bookings scheduled.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              return _buildBookingQueueCard(bookings[index]);
            },
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildBookingQueueCard(BookingModel booking) {
    Color statusColor = AppColors.warning;
    if (booking.status == 'in_progress') {
      statusColor = AppColors.success;
    } else if (booking.status == 'completed') {
      statusColor = AppColors.info;
    } else if (booking.status == 'cancelled') {
      statusColor = AppColors.error;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Slot: ${booking.scheduledStart.split('T').last.substring(0, 5)}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
          const Divider(height: 20, color: AppColors.border),
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: AppColors.surface,
                child: Icon(LucideIcons.user, color: AppColors.textSecondary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Booking ID: #${booking.id.substring(0, 8)}', style: const TextStyle(fontWeight: FontWeight.bold)),
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
                  Text('Pos: #${booking.queuePosition}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('${booking.estimatedWaitMinutes} mins wait', style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Action Buttons based on state
          if (booking.status == 'pending' || booking.status == 'confirmed')
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                    onPressed: () => _updateStatus(booking.id, 'no_show'),
                    child: const Text('NO SHOW'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _updateStatus(booking.id, 'in_progress');
                      _simulateLiveSyncUpdate(booking.id, booking.queuePosition - 1);
                    },
                    child: const Text('START SERVICE'),
                  ),
                ),
              ],
            )
          else if (booking.status == 'in_progress')
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
              onPressed: () {
                _updateStatus(booking.id, 'completed');
                _simulateLiveSyncUpdate(booking.id, 0);
              },
              child: const Text('COMPLETE APPOINTMENT'),
            ),
        ],
      ),
    );
  }

  Widget _buildScheduleTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(LucideIcons.clock, size: 64, color: AppColors.primary),
          const SizedBox(height: 16),
          Text(
            'Manage Working Hours',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'Configure your weekly opening and closing schedules. Customers can only book slots within this time interval.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),
          
          _buildTimeConfigRow('Shift Starts:', _startTime, (val) {
            setState(() {
              _startTime = val;
            });
          }),
          const SizedBox(height: 16),
          _buildTimeConfigRow('Shift Closes:', _endTime, (val) {
            setState(() {
              _endTime = val;
            });
          }),
          
          const SizedBox(height: 48),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Weekly schedule updated!'), backgroundColor: AppColors.success),
              );
            },
            child: const Text('SAVE TIMINGS'),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeConfigRow(String label, String value, Function(String) onChange) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          DropdownButton<String>(
            value: value,
            dropdownColor: AppColors.surface,
            iconEnabledColor: AppColors.primary,
            underline: const SizedBox.shrink(),
            onChanged: (val) {
              if (val != null) onChange(val);
            },
            items: ['08:00', '09:00', '10:00', '11:00', '20:00', '21:00', '22:00']
                .map((time) => DropdownMenuItem(value: time, child: Text(time)))
                .toList(),
          ),
        ],
      ),
    );
  }

  void _updateStatus(String bookingId, String status) {
    context.read<BookingBloc>().add(
      UpdateBookingStatus(bookingId: bookingId, status: status),
    );
  }

  void _simulateLiveSyncUpdate(String bookingId, int nextPosition) {
    // Send event through WebSocket to push live sync notifications to listening clients
    widget.webSocketClient.sendEvent('queue_update', {
      'booking_id': bookingId,
      'current_position': nextPosition,
      'estimated_wait_min': nextPosition * 15,
    });
  }
}
