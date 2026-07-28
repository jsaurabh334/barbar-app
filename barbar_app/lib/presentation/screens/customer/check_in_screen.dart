import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/booking_model.dart';
import '../../bloc/check_in/check_in_bloc.dart';
import '../../bloc/check_in/check_in_event.dart';
import '../../bloc/check_in/check_in_state.dart';

class CheckInScreen extends StatefulWidget {
  final String bookingId;

  const CheckInScreen({super.key, required this.bookingId});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  @override
  void initState() {
    super.initState();
    context.read<CheckInBloc>().add(LoadCheckInData(widget.bookingId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('CHECK IN')),
      body: BlocConsumer<CheckInBloc, CheckInState>(
        listener: (context, state) {
          if (state is CheckInFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error), backgroundColor: AppColors.error),
            );
          }
        },
        builder: (context, state) {
          if (state is CheckInLoading && state is! CheckInDataLoaded) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (state is CheckInDataLoaded) return _buildPreCheckIn(state.booking);
          if (state is CheckedInSuccess) return _buildPostCheckIn(state.booking);
          if (state is ImComingSuccess) return _buildImComing(state.booking);
          if (state is CheckInFailure && state is! CheckInDataLoaded) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.alertCircle, size: 48, color: AppColors.error.withValues(alpha: 0.6)),
                  const SizedBox(height: 12),
                  Text(state.error, style: const TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 16),
                  _actionButton('RETRY', AppColors.primary, () {
                    context.read<CheckInBloc>().add(LoadCheckInData(widget.bookingId));
                  }),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildPreCheckIn(BookingModel booking) {
    final bool canCheckIn = booking.status == 'confirmed';
    final bool hasQueue = booking.queueAssignedAt != null;
    final bool isLate = booking.isLate;
    final bool hasImComing = booking.imComingAt != null;
    final String? graceUntil = booking.graceExtendedUntil;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _bookingHeader(booking),
          const SizedBox(height: 16),
          _infoCard(booking),
          const SizedBox(height: 16),
          if (isLate) _lateWarning(graceUntil),
          if (hasImComing) _imComingBanner(),
          if (canCheckIn) ...[
            if (hasQueue) _checkInActions(booking),
            if (!hasQueue) _queueNotAssigned(),
          ],
          if (!canCheckIn && !hasQueue) _statusInfo(booking),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPostCheckIn(BookingModel booking) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _bookingHeader(booking),
          const SizedBox(height: 16),
          _infoCard(booking),
          const SizedBox(height: 24),
          if (booking.status == 'checked_in' || booking.status == 'waiting')
            _queueStatus(booking),
          if (booking.status == 'next')
            _nextBanner(),
          if (booking.status == 'in_progress')
            _inProgressBanner(),
          _callActions(booking),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildImComing(BookingModel booking) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _bookingHeader(booking),
          const SizedBox(height: 16),
          _imComingBanner(),
          const SizedBox(height: 16),
          _infoCard(booking),
          const SizedBox(height: 24),
          if (booking.status == 'confirmed')
            Column(
              children: [
                const Text(
                  'The shop knows you\'re on your way!',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your grace period has been extended. Please arrive soon.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                _actionButton('CHECK IN AT SHOP', AppColors.primary, () {
                  context.read<CheckInBloc>().add(CheckInManual(bookingId: booking.id));
                }),
              ],
            ),
          if (booking.status == 'checked_in' || booking.status == 'waiting')
            _queueStatus(booking),
          _callActions(booking),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _bookingHeader(BookingModel booking) {
    final dt = DateTime.tryParse(booking.scheduledStart);
    final time = dt != null
        ? '${dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour)}:${dt.minute.toString().padLeft(2, '0')} ${dt.hour >= 12 ? "PM" : "AM"}'
        : '';
    final date = dt != null ? '${dt.day}/${dt.month}/${dt.year}' : '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            child: const Icon(LucideIcons.scissors, size: 28, color: AppColors.primary),
          ),
          const SizedBox(height: 12),
          Text(booking.shopName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('$date at $time', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          if (booking.staff != null) ...[
            const SizedBox(height: 4),
            Text('with ${booking.staff!['name'] ?? ''}',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
          ],
        ],
      ),
    );
  }

  Widget _infoCard(BookingModel booking) {
    int totalMinutes = 0;
    double total = 0;
    for (final s in booking.services) {
      totalMinutes += s.durationMinutes;
      total += s.price;
    }

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
          const Text('Booking Info', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 12),
          _infoRow(LucideIcons.hash, 'ID', booking.id.substring(0, 8).toUpperCase()),
          const Divider(height: 16, color: AppColors.border),
          _infoRow(LucideIcons.hourglass, 'Duration', '$totalMinutes min'),
          const Divider(height: 16, color: AppColors.border),
          _infoRow(LucideIcons.tag, 'Status', booking.status.toUpperCase()),
          const Divider(height: 16, color: AppColors.border),
          _infoRow(LucideIcons.creditCard, 'Payment', booking.paymentStatus.toUpperCase()),
          if (booking.services.isNotEmpty) ...[
            const Divider(height: 16, color: AppColors.border),
            const Text('Services', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            ...booking.services.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Icon(LucideIcons.scissors, size: 12, color: AppColors.textMuted),
                  const SizedBox(width: 8),
                  Expanded(child: Text(s.name, style: const TextStyle(fontSize: 13))),
                  Text('₹${s.price.toInt()}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                ],
              ),
            )),
            const Divider(height: 16, color: AppColors.border),
            Row(
              children: [
                const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const Spacer(),
                Text('₹${total.toInt()}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.primary)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _checkInActions(BookingModel booking) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Text('Ready for your appointment?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Check in to let the shop know you\'ve arrived',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: _actionButton('CHECK IN AT SHOP', AppColors.success, () {
              context.read<CheckInBloc>().add(CheckInManual(bookingId: booking.id));
            }),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: _actionButton('I\'M ON MY WAY', AppColors.warning, outlined: true, () {
              context.read<CheckInBloc>().add(ImComing(booking.id));
            }),
          ),
        ],
      ),
    );
  }

  Widget _queueNotAssigned() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(LucideIcons.clock, size: 32, color: AppColors.warning),
          const SizedBox(height: 12),
          const Text('Queue Not Yet Assigned',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            'Your queue position will be assigned closer to your appointment time.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: _actionButton('I\'M ON MY WAY', AppColors.warning, outlined: true, () {
              context.read<CheckInBloc>().add(ImComing(widget.bookingId));
            }),
          ),
        ],
      ),
    );
  }

  Widget _queueStatus(BookingModel booking) {
    final waitMin = booking.estimatedWaitMinutes;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withValues(alpha: 0.1), AppColors.primary.withValues(alpha: 0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Text('Your Position', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Text(
            '#${booking.queuePosition}',
            style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: AppColors.primary),
          ),
          const SizedBox(height: 8),
          Text(
            waitMin > 0 ? 'Est. wait: ~$waitMin min' : 'You\'re next!',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: waitMin > 0 ? AppColors.textSecondary : AppColors.success,
            ),
          ),
        ],
      ),
    );
  }

  Widget _nextBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.success.withValues(alpha: 0.15), AppColors.success.withValues(alpha: 0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.chevronsRight, color: AppColors.success, size: 20),
          SizedBox(width: 8),
          Text('You\'re Next! Get Ready',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.success)),
        ],
      ),
    );
  }

  Widget _inProgressBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.info.withValues(alpha: 0.15), AppColors.info.withValues(alpha: 0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.4)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.scissors, color: AppColors.info, size: 20),
          SizedBox(width: 8),
          Text('Service In Progress',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.info)),
        ],
      ),
    );
  }

  Widget _lateWarning(String? graceUntil) {
    String msg = 'You\'re late! Check in ASAP to avoid losing your spot.';
    if (graceUntil != null) {
      final gt = DateTime.tryParse(graceUntil);
      if (gt != null) {
        final remaining = gt.difference(DateTime.now());
        if (remaining.isNegative) {
          msg = 'Your grace period has expired.';
        } else {
          msg = 'Grace period ends in ${remaining.inMinutes} min. Check in now!';
        }
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.alertTriangle, color: AppColors.error),
          const SizedBox(width: 12),
          Expanded(child: Text(msg, style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _imComingBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: const Row(
        children: [
          Icon(LucideIcons.checkCircle, color: AppColors.warning),
          SizedBox(width: 12),
          Text('You\'ve notified the shop. Grace period extended.',
            style: TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _statusInfo(BookingModel booking) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(_statusIcon(booking.status), color: _statusColor(booking.status)),
          const SizedBox(width: 12),
          Expanded(
            child: Text('Status: ${_statusLabel(booking.status)}',
              style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _callActions(BookingModel booking) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Text('Need Help?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 12),
        Row(
          children: [
            if (booking.canCallShop && booking.maskedShopPhone != null)
              Expanded(
                child: _actionButton('CALL SHOP', AppColors.success, outlined: true, () {
                  _launchPhone(context, booking.maskedShopPhone!);
                }),
              ),
            if (booking.canCallShop && booking.canCallCustomer) const SizedBox(width: 12),
            if (booking.canCallCustomer && booking.maskedCustomerPhone != null)
              Expanded(
                child: _actionButton('CALL CUSTOMER', AppColors.info, outlined: true, () {
                  _launchPhone(context, booking.maskedCustomerPhone!);
                }),
              ),
          ],
        ),
      ],
    );
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'confirmed': return LucideIcons.checkCircle;
      case 'checked_in': return LucideIcons.logIn;
      case 'waiting': return LucideIcons.clock;
      case 'next': return LucideIcons.chevronsRight;
      case 'in_progress': return LucideIcons.scissors;
      case 'completed': return LucideIcons.checkCircle;
      case 'cancelled': return LucideIcons.xCircle;
      default: return LucideIcons.clock;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'confirmed': return AppColors.success;
      case 'checked_in': return AppColors.info;
      case 'waiting': return AppColors.warning;
      case 'next': return AppColors.success;
      case 'in_progress': return AppColors.info;
      case 'completed': return AppColors.success;
      case 'cancelled': return AppColors.error;
      default: return AppColors.textMuted;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'confirmed': return 'Confirmed';
      case 'checked_in': return 'Checked In';
      case 'waiting': return 'Waiting';
      case 'next': return 'You\'re Next';
      case 'in_progress': return 'In Progress';
      case 'completed': return 'Completed';
      case 'cancelled': return 'Cancelled';
      default: return status;
    }
  }

  Widget _actionButton(String label, Color color, VoidCallback onTap, {bool outlined = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: outlined ? Colors.transparent : color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: outlined ? color.withValues(alpha: 0.6) : Colors.transparent),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.primary),
        const SizedBox(width: 8),
        SizedBox(width: 64, child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12))),
        Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
      ],
    );
  }

  Future<void> _launchPhone(BuildContext context, String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch dialer for $phone')),
      );
    }
  }
}
