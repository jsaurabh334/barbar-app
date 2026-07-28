import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/booking_model.dart';
import '../bloc/barber_queue/barber_queue_bloc.dart';
import '../bloc/barber_queue/barber_queue_event.dart';
import '../bloc/barber_queue/barber_queue_state.dart';

class BarberQueueScreen extends StatefulWidget {
  const BarberQueueScreen({super.key});

  @override
  State<BarberQueueScreen> createState() => _BarberQueueScreenState();
}

class _BarberQueueScreenState extends State<BarberQueueScreen> {
  @override
  void initState() {
    super.initState();
    context.read<BarberQueueBloc>().add(const LoadTodayQueue());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F15),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F15),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.maybePop(context);
            }
          },
          tooltip: 'Back',
        ),
        title: Text(
          'Live Queue Tracker',
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, color: AppColors.primary, size: 20),
            tooltip: 'Refresh Queue',
            onPressed: () {
              context.read<BarberQueueBloc>().add(const LoadTodayQueue());
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: BlocConsumer<BarberQueueBloc, BarberQueueState>(
          listener: (context, state) {
            if (state is BarberQueueFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.error, style: GoogleFonts.outfit(color: Colors.white)),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
            if (state is BarberQueueActionSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message, style: GoogleFonts.outfit(color: Colors.white)),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is BarberQueueLoading) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primary));
            }
            if (state is TodayQueueLoaded) return _buildQueue(state);
            if (state is BarberQueueFailure) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.alertCircle, size: 48, color: AppColors.error),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        state.error,
                        style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      _actionButton('RETRY QUEUE', AppColors.primary, () {
                        context.read<BarberQueueBloc>().add(const LoadTodayQueue());
                      }),
                    ],
                  ),
                ),
              );
            }
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          },
        ),
      ),
    );
  }

  Widget _buildQueue(TodayQueueLoaded state) {
    final total = state.serving.length + state.next.length + state.waiting.length + state.late.length + state.upcoming.length;
    final isEmpty = total == 0;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: _buildHeaderCard(state, total)),
        if (state.availableStaff.length > 1)
          SliverToBoxAdapter(child: _buildStaffFilter(state)),
        
        if (state.serving.isNotEmpty)
          SliverToBoxAdapter(child: _sectionHeader('NOW SERVING', AppColors.success, LucideIcons.scissors, state.serving.length)),
        if (state.serving.isNotEmpty)
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (c, i) => _buildQueueCard(state.serving[i], isServing: true),
              childCount: state.serving.length,
            ),
          ),

        if (state.next.isNotEmpty)
          SliverToBoxAdapter(child: _sectionHeader('NEXT IN LINE', AppColors.info, LucideIcons.chevronsRight, state.next.length)),
        if (state.next.isNotEmpty)
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (c, i) => _buildQueueCard(state.next[i]),
              childCount: state.next.length,
            ),
          ),

        if (state.waiting.isNotEmpty)
          SliverToBoxAdapter(child: _sectionHeader('WAITING', AppColors.warning, LucideIcons.clock, state.waiting.length)),
        if (state.waiting.isNotEmpty)
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (c, i) => _buildQueueCard(state.waiting[i]),
              childCount: state.waiting.length,
            ),
          ),

        if (state.late.isNotEmpty)
          SliverToBoxAdapter(child: _sectionHeader('LATE / OVERDUE', AppColors.error, LucideIcons.alertTriangle, state.late.length)),
        if (state.late.isNotEmpty)
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (c, i) => _buildQueueCard(state.late[i], isLate: true),
              childCount: state.late.length,
            ),
          ),

        if (state.upcoming.isNotEmpty)
          SliverToBoxAdapter(child: _sectionHeader('UPCOMING TODAY', AppColors.textSecondary, LucideIcons.calendar, state.upcoming.length)),
        if (state.upcoming.isNotEmpty)
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (c, i) => _buildQueueCard(state.upcoming[i]),
              childCount: state.upcoming.length,
            ),
          ),

        if (isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _buildEmptyState(state),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }

  Widget _buildHeaderCard(TodayQueueLoaded state, int total) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1E2E), Color(0xFF141420)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Shop Info & Actions
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                ),
                child: const Icon(LucideIcons.store, size: 22, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.shopName.isNotEmpty ? state.shopName : 'My Hair Studio',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (state.shopAddress.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(LucideIcons.mapPin, size: 12, color: Colors.white54),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              state.shopAddress,
                              style: GoogleFonts.outfit(fontSize: 12, color: Colors.white54),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                ),
                child: Text(
                  '$total Total',
                  style: GoogleFonts.outfit(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => context.read<BarberQueueBloc>().add(
                  LoadTodayQueueRefresh(staffId: state.activeStaffId),
                ),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2B2B3D),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: const Icon(LucideIcons.refreshCw, size: 16, color: AppColors.primary),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 14),

          // Status Badges Overview Bar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _summaryChip('Serving', state.serving.length, AppColors.success),
                const SizedBox(width: 8),
                _summaryChip('Next', state.next.length, AppColors.info),
                const SizedBox(width: 8),
                _summaryChip('Waiting', state.waiting.length, AppColors.warning),
                const SizedBox(width: 8),
                _summaryChip('Late', state.late.length, AppColors.error),
                const SizedBox(width: 8),
                _summaryChip('Upcoming', state.upcoming.length, Colors.white54),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: GoogleFonts.outfit(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w500),
          ),
          Text(
            '$count',
            style: GoogleFonts.outfit(fontSize: 12, color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffFilter(TodayQueueLoaded state) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _filterChip('All Staff', state.activeStaffId == null, () {
            context.read<BarberQueueBloc>().add(const FilterByStaff(null));
          }),
          ...state.availableStaff.map((staff) {
            final id = staff['id'] as String?;
            final name = staff['name'] as String?;
            return _filterChip(name ?? 'Staff', state.activeStaffId == id, () {
              context.read<BarberQueueBloc>().add(FilterByStaff(id));
            });
          }),
        ],
      ),
    );
  }

  Widget _filterChip(String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : const Color(0xFF1E1E2E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? AppColors.primary : Colors.white12),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            color: isActive ? Colors.black : Colors.white70,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, Color color, IconData icon, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 15, color: color),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: color, letterSpacing: 0.8),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: GoogleFonts.outfit(color: color, fontWeight: FontWeight.bold, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQueueCard(BookingModel booking, {bool isServing = false, bool isLate = false}) {
    final dt = DateTime.tryParse(booking.scheduledStart);
    final time = dt != null
        ? '${dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour)}:${dt.minute.toString().padLeft(2, '0')} ${dt.hour >= 12 ? "PM" : "AM"}'
        : '';

    Color borderColor = Colors.white12;
    if (isServing) borderColor = AppColors.success.withValues(alpha: 0.5);
    else if (isLate) borderColor = AppColors.error.withValues(alpha: 0.5);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: isServing ? 1.5 : 1.0),
        boxShadow: isServing
            ? [
                BoxShadow(
                  color: AppColors.success.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : [],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: isServing
                      ? AppColors.success.withValues(alpha: 0.2)
                      : AppColors.primary.withValues(alpha: 0.15),
                  child: Icon(
                    LucideIcons.user,
                    size: 18,
                    color: isServing ? AppColors.success : AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.customerName,
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        booking.services.map((s) => s.name).join(', '),
                        style: GoogleFonts.outfit(fontSize: 12, color: Colors.white54),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (booking.queuePosition > 0 || isServing)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isServing ? AppColors.success.withValues(alpha: 0.15) : AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isServing ? AppColors.success.withValues(alpha: 0.4) : AppColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      isServing ? 'SERVING' : '#${booking.queuePosition}',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: isServing ? AppColors.success : AppColors.primary,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(LucideIcons.clock, size: 13, color: Colors.white38),
                const SizedBox(width: 4),
                Text(time, style: GoogleFonts.outfit(fontSize: 12, color: Colors.white38)),
                if (booking.staff != null) ...[
                  const SizedBox(width: 14),
                  const Icon(LucideIcons.user, size: 13, color: Colors.white38),
                  const SizedBox(width: 4),
                  Text(booking.staff!['name'] ?? '', style: GoogleFonts.outfit(fontSize: 12, color: Colors.white38)),
                ],
                if (booking.estimatedWaitMinutes > 0) ...[
                  const SizedBox(width: 14),
                  const Icon(LucideIcons.hourglass, size: 13, color: Colors.white38),
                  const SizedBox(width: 4),
                  Text('~${booking.estimatedWaitMinutes} min', style: GoogleFonts.outfit(fontSize: 12, color: Colors.white38)),
                ],
              ],
            ),
            if (isLate) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(LucideIcons.alertTriangle, size: 13, color: AppColors.error),
                  const SizedBox(width: 4),
                  Text('Late for appointment', style: GoogleFonts.outfit(fontSize: 12, color: AppColors.error, fontWeight: FontWeight.w600)),
                  if (booking.graceExtendedUntil != null) ...[
                    const SizedBox(width: 6),
                    Text('(Grace: ${_formatTimeShort(booking.graceExtendedUntil)})', style: GoogleFonts.outfit(fontSize: 11, color: Colors.white38)),
                  ],
                ],
              ),
            ],
            const SizedBox(height: 10),
            const Divider(color: Colors.white10, height: 1),
            const SizedBox(height: 10),
            if (!isServing) ...[
              Row(
                children: [
                  if (booking.status == 'checked_in' || booking.status == 'waiting' || booking.status == 'next')
                    Expanded(
                      child: _miniButton('START SERVICE', AppColors.success, () {
                        context.read<BarberQueueBloc>().add(StartService(booking.id));
                      }),
                    ),
                  if (booking.status == 'checked_in' || booking.status == 'waiting' || booking.status == 'next') ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: _miniButton('SKIP', AppColors.warning, () {
                        context.read<BarberQueueBloc>().add(SkipCustomer(booking.id));
                      }),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _miniButton('NO-SHOW', AppColors.error, () {
                        _confirmNoShow(booking);
                      }),
                    ),
                  ],
                  if (booking.status == 'confirmed')
                    Expanded(
                      child: _miniButton('CHECK IN', AppColors.info, () {
                        context.read<BarberQueueBloc>().add(StartService(booking.id));
                      }),
                    ),
                ],
              ),
            ],
            if (isServing) ...[
              Row(
                children: [
                  Expanded(
                    child: _miniButton('FINISH SERVICE', AppColors.success, () {
                      context.read<BarberQueueBloc>().add(CompleteService(booking.id));
                    }),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(TodayQueueLoaded state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 1.5),
              ),
              child: const Icon(LucideIcons.calendarCheck, size: 38, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            Text(
              'No Active Clients in Queue',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'New online appointments, customer check-ins, or walk-ins will automatically show up here.',
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: Colors.white54,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E1E2E),
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5), width: 1.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
              onPressed: () {
                context.read<BarberQueueBloc>().add(LoadTodayQueueRefresh(staffId: state.activeStaffId));
              },
              icon: const Icon(LucideIcons.refreshCw, size: 16, color: AppColors.primary),
              label: Text('Refresh Today\'s Queue', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmNoShow(BookingModel booking) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Mark as No-Show?', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
        content: Text(
          '${booking.customerName} will be marked as no-show for ${_formatTime(booking.scheduledStart)}.',
          style: GoogleFonts.outfit(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.outfit(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<BarberQueueBloc>().add(MarkNoShow(booking.id));
            },
            child: Text('Confirm', style: GoogleFonts.outfit(color: AppColors.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _miniButton(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.outfit(color: color, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
          ),
        ),
      ),
    );
  }

  Widget _actionButton(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(color: color, fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ),
    );
  }

  String _formatTimeShort(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso);
      final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      return '$h:${dt.minute.toString().padLeft(2, '0')} ${dt.hour >= 12 ? "PM" : "AM"}';
    } catch (_) {
      return '';
    }
  }

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso);
      final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      return '$h:${dt.minute.toString().padLeft(2, '0')} ${dt.hour >= 12 ? "PM" : "AM"}';
    } catch (_) {
      return '';
    }
  }
}
