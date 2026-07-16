import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/network/websocket_client.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/booking_model.dart';
import '../../domain/repositories/barber_repository.dart';
import '../bloc/booking/booking_bloc.dart';
import '../bloc/booking/booking_event.dart';
import '../bloc/booking/booking_state.dart';
import '../bloc/barber_availability/barber_availability_bloc.dart';
import '../bloc/barber_availability/barber_availability_event.dart';
import '../bloc/barber_availability/barber_availability_state.dart';
import '../bloc/notification/notification_bloc.dart';
import '../bloc/notification/notification_event.dart';
import '../widgets/glass_card.dart';
import '../widgets/notification_bell.dart';
import 'barber/booking_detail_screen.dart';

class BarberDashboardScreen extends StatefulWidget {
  final WebSocketClient webSocketClient;
  final BarberRepository barberRepository;

  const BarberDashboardScreen({
    super.key,
    required this.webSocketClient,
    required this.barberRepository,
  });

  @override
  State<BarberDashboardScreen> createState() => _BarberDashboardScreenState();
}

class _BarberDashboardScreenState extends State<BarberDashboardScreen> {
  String _barberStatus = 'offline';
  int _todayBookings = 0;
  double _earningsToday = 0;
  int _pendingHomeServices = 0;
  int _pendingReviews = 0;
  String _shopName = '';
  String _shiftStart = '--:--';
  String _shiftEnd = '--:--';
  List<BookingModel> _bookings = [];
  List<Map<String, dynamic>> _staffList = [];
  String? _selectedStaffFilter;

  @override
  void initState() {
    super.initState();
    context.read<BookingBloc>().add(FetchBarberBookings());
    _loadDashboard();
    _fetchStaff();

    widget.webSocketClient.events.listen((event) {
      if (!mounted) return;
      final type = event['type'] as String?;
      if (type == 'notification') {
        final payload = event['payload'] as Map<String, dynamic>?;
        if (payload != null) {
          context.read<NotificationBloc>().add(NewWebSocketNotification(payload));
        }
        return;
      }
      if (type == 'queue_update') {
        context.read<BookingBloc>().add(FetchBarberBookings());
        _loadDashboard();
      }
    });
  }

  Future<void> _fetchStaff() async {
    try {
      final staff = await widget.barberRepository.getStaff();
      if (mounted) {
        setState(() => _staffList = staff);
      }
    } catch (_) {}
  }

    Map<String, dynamic>? _barberData;

  Future<void> _loadDashboard() async {
    try {
      final dashboard = await widget.barberRepository.getDashboard();
      if (mounted) {
        setState(() {
          _barberData = dashboard['barber'] as Map<String, dynamic>?;
          _barberStatus = dashboard['barber']['status'] as String? ?? 'inactive';
          _todayBookings = dashboard['today_bookings'] as int? ?? 0;
          _earningsToday = (dashboard['earnings_today'] as num?)?.toDouble() ?? 0;
          _pendingHomeServices = dashboard['pending_home_services'] as int? ?? 0;
          _pendingReviews = dashboard['pending_reviews'] as int? ?? 0;
          _shopName = (dashboard['barber']['shop_name'] as String?) ?? 'My Shop';
          _shiftStart = (dashboard['barber']['start_time'] as String?) ?? '09:00';
          _shiftEnd = (dashboard['barber']['end_time'] as String?) ?? '21:00';
        });
      }
    } catch (_) {}
  }

  int _getProfileCompletionPercent() {
    final b = _barberData;
    if (b == null) return 0;
    int total = 0;
    int filled = 0;
    final checks = ['shop_name', 'address', 'city', 'start_time', 'end_time'];
    for (final key in checks) {
      total++;
      final val = b[key];
      if (val != null && val is String && val.trim().isNotEmpty) filled++;
    }
    final lat = (b['latitude'] as num?)?.toDouble() ?? 0;
    final lng = (b['longitude'] as num?)?.toDouble() ?? 0;
    total++;
    if (lat != 0 && lng != 0) filled++;
    return (filled / total * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_shopName.isEmpty ? 'DASHBOARD' : _shopName.toUpperCase()),
        actions: [
          const NotificationBellIcon(),
        ],
      ),
      body: BlocListener<BookingBloc, BookingState>(
        listener: (context, state) {
          if (state is BookingFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        child: RefreshIndicator(
        onRefresh: () async {
          _loadDashboard();
          context.read<BookingBloc>().add(FetchBarberBookings());
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildStatusBanner(),
              const SizedBox(height: 16),
              _buildProfileCompletionCard(),
              const SizedBox(height: 16),
              _buildShiftOverview(),
              const SizedBox(height: 20),
              _buildQuickStats(),
              const SizedBox(height: 24),
              const Text('TODAY\'S QUEUE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary)),
              const SizedBox(height: 12),
              if (_staffList.isNotEmpty) ...[
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildFilterChip('All', null, _selectedStaffFilter == null),
                      ..._staffList.map((staff) {
                        final name = staff['name'] as String? ?? 'Staff';
                        return _buildFilterChip(name, staff['id'] as String?, _selectedStaffFilter == staff['id']);
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              _buildActiveQueue(),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildProfileCompletionCard() {
    final pct = _getProfileCompletionPercent();
    if (pct >= 100) return const SizedBox.shrink();
    final color = pct < 50 ? AppColors.error : Colors.orange;
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(LucideIcons.alertTriangle, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Profile ${pct}% complete', style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13)),
                  const SizedBox(height: 4),
                  const Text('Complete your shop details in Settings', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBanner() {
    final isOnline = _barberStatus == 'active' || _barberStatus == 'online';
    final statusColor = isOnline ? AppColors.success : AppColors.textSecondary;
    final statusText = isOnline ? 'Online' : _barberStatus.toUpperCase();
    final statusIcon = isOnline ? LucideIcons.wifi : LucideIcons.wifiOff;

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(statusIcon, color: statusColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You are $statusText',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isOnline ? 'Customers can book appointments' : 'Shop is closed for bookings',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          BlocConsumer<BarberAvailabilityBloc, BarberAvailabilityState>(
            listener: (context, state) {
              if (state is BarberAvailabilitySuccess) {
                // Refresh dashboard to reflect new status
                _loadDashboard();
              } else if (state is BarberAvailabilityFailure) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.error), backgroundColor: AppColors.error),
                );
              }
            },
            builder: (context, state) {
              final isLoading = state is BarberAvailabilityLoading;
              return isLoading
                  ? const SizedBox(width: 48, height: 48, child: Center(child: CircularProgressIndicator()))
                  : Switch(
                      value: isOnline,
                      activeColor: AppColors.success,
                      onChanged: (val) {
                        context.read<BarberAvailabilityBloc>().add(
                          UpdateStatus(isAvailable: val, status: val ? 'active' : 'inactive'),
                        );
                      },
                    );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        _buildStatCard(
          icon: LucideIcons.calendar,
          label: 'Today',
          value: '$_todayBookings',
          color: AppColors.info,
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          icon: LucideIcons.indianRupee,
          label: 'Earnings',
          value: '₹${_earningsToday.toStringAsFixed(0)}',
          color: AppColors.success,
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          icon: LucideIcons.home,
          label: 'Home Svc',
          value: '$_pendingHomeServices',
          color: AppColors.warning,
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          icon: LucideIcons.star,
          label: 'Reviews',
          value: '$_pendingReviews',
          color: AppColors.primary,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color),
            ),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _buildShiftOverview() {
    final isOnline = _barberStatus == 'active' || _barberStatus == 'online';
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(LucideIcons.clock, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Current Shift', style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(LucideIcons.calendarDays, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text('Starts: $_shiftStart', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(width: 16),
                    const Icon(LucideIcons.clock4, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text('Closes: $_shiftEnd', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: (isOnline ? AppColors.success : AppColors.error).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isOnline ? 'Active' : 'Closed',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isOnline ? AppColors.success : AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }


  List<BookingModel> _filteredBookings() {
    if (_selectedStaffFilter == null) return _bookings;
    return _bookings.where((b) => b.staffId == _selectedStaffFilter).toList();
  }

  Widget _buildActiveQueue() {
    return BlocConsumer<BookingBloc, BookingState>(
      listener: (context, state) {
        if (state is BookingsLoaded) {
          setState(() => _bookings = state.bookings);
        }
      },
      builder: (context, state) {
        if (state is BookingLoading && _bookings.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        final displayBookings = _filteredBookings();

        if (displayBookings.isEmpty) {
          final label = _selectedStaffFilter != null ? ' for this staff' : '';
          return GlassCard(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                const Icon(LucideIcons.calendarCheck, size: 48, color: AppColors.textMuted),
                const SizedBox(height: 12),
                Text('No bookings$label today', style: const TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          );
        }

        return Column(
          children: displayBookings.take(5).map((booking) => _buildBookingCard(booking)).toList(),
        );
      },
    );
  }

  void _showCustomerDetails(BookingModel booking) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BarberBookingDetailScreen(booking: booking),
      ),
    );
  }

  void _startOrAcceptBooking(BookingModel booking) {
    if (booking.status == 'pending') {
      context.read<BookingBloc>().add(
        UpdateBookingStatus(bookingId: booking.id, status: 'confirmed'),
      );
    } else {
      context.read<BookingBloc>().add(
        UpdateBookingStatus(bookingId: booking.id, status: 'in_progress'),
      );
    }
  }

  Widget _buildBookingCard(BookingModel booking) {
    final isInProgress = booking.status == 'in_progress';
    final isPending = booking.status == 'pending';
    final isConfirmed = booking.status == 'confirmed';
    final isCompleted = booking.status == 'completed';
    final isCancelled = booking.status == 'cancelled';
    final isPaid = booking.paymentStatus == 'paid';

    Color statusColor = AppColors.warning;
    if (isInProgress) statusColor = AppColors.success;
    else if (isCompleted) statusColor = AppColors.info;
    else if (isCancelled) statusColor = AppColors.error;
    else if (isPending) statusColor = AppColors.warning;

    return GestureDetector(
      onTap: () => _showCustomerDetails(booking),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isInProgress ? AppColors.success.withValues(alpha: 0.5) : AppColors.border,
            width: isInProgress ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
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
                        Text(
                          booking.customerName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${booking.scheduledStart.split('T').last.length >= 5 ? booking.scheduledStart.split('T').last.substring(0, 5) : booking.scheduledStart.split('T').last}  •  ${booking.services.map((s) => s.name).join(', ')}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        if (booking.staff != null) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(LucideIcons.user, size: 10, color: AppColors.textMuted),
                              const SizedBox(width: 4),
                              Text(
                                booking.staff!['name'] ?? 'Staff',
                                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isInProgress ? 'IN PROGRESS' : booking.status.toUpperCase(),
                      style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10),
                    ),
                  ),
                ],
              ),
            ),
            if (!isCompleted && !isCancelled || (isCompleted && !isPaid))
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Row(
                  children: [
                    if (isCompleted && !isPaid)
                      Expanded(
                        child: _actionButton(
                          label: 'COLLECT CASH',
                          color: AppColors.success,
                          onTap: () {
                            context.read<BookingBloc>().add(
                              PayBooking(
                                bookingId: booking.id,
                                method: 'cash',
                                status: 'paid',
                                reference: 'CASH${DateTime.now().millisecondsSinceEpoch}',
                              ),
                            );
                          },
                        ),
                      ),
                    if (isInProgress)
                      Expanded(
                        child: _actionButton(
                          label: 'FINISH SERVICE',
                          color: AppColors.success,
                          onTap: () {
                            context.read<BookingBloc>().add(
                              UpdateBookingStatus(bookingId: booking.id, status: 'completed'),
                            );
                          },
                        ),
                      ),
                    if (isPending) ...[
                      Expanded(
                        child: _actionButton(
                          label: 'ACCEPT',
                          color: AppColors.primary,
                          onTap: () => _startOrAcceptBooking(booking),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _actionButton(
                          label: 'DECLINE',
                          color: AppColors.error,
                          outlined: true,
                          onTap: () {
                            context.read<BookingBloc>().add(
                              UpdateBookingStatus(bookingId: booking.id, status: 'cancelled'),
                            );
                          },
                        ),
                      ),
                    ],
                    if (isConfirmed) ...[
                      Expanded(
                        child: _actionButton(
                          label: 'START SERVICE',
                          color: AppColors.primary,
                          onTap: () => _startOrAcceptBooking(booking),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _actionButton(
                          label: 'NO SHOW',
                          color: AppColors.error,
                          outlined: true,
                          onTap: () {
                            context.read<BookingBloc>().add(
                              UpdateBookingStatus(bookingId: booking.id, status: 'cancelled'),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String? id, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() => _selectedStaffFilter = id);
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool outlined = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: outlined ? Colors.transparent : color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.6)),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
