import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/booking_model.dart';
import '../../bloc/booking/booking_bloc.dart';
import '../../bloc/booking/booking_event.dart';

class BarberBookingDetailScreen extends StatelessWidget {
  final BookingModel booking;

  const BarberBookingDetailScreen({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final customerMap = booking.customer;
    final name = customerMap?['full_name'] as String? ?? booking.customerName;
    final phone = customerMap?['phone'] as String? ?? '';
    final email = customerMap?['email'] as String? ?? '';
    final isPending = booking.status == 'pending';
    final isConfirmed = booking.status == 'confirmed';
    final isInProgress = booking.status == 'in_progress';
    final isCompleted = booking.status == 'completed';
    final isPaid = booking.paymentStatus == 'paid';

    double total = 0;
    int totalMinutes = 0;
    for (final s in booking.services) {
      total += s.price;
      totalMinutes += s.durationMinutes;
    }
    total += booking.travelCharge;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('BOOKING DETAILS'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Customer Header
            Container(
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
                    radius: 36,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                    child: const Icon(LucideIcons.user, size: 36, color: AppColors.primary),
                  ),
                  const SizedBox(height: 12),
                  Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    phone.isNotEmpty ? phone : 'No phone',
                    style: TextStyle(
                      fontSize: 14,
                      color: phone.isNotEmpty ? AppColors.textSecondary : AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (phone.isNotEmpty)
                        _actionChip(
                          icon: LucideIcons.phone,
                          label: 'Call',
                          color: AppColors.success,
                          onTap: () => _launchPhone(context, phone),
                        ),
                      if (phone.isNotEmpty) const SizedBox(width: 12),
                      if (email.isNotEmpty)
                        _actionChip(
                          icon: LucideIcons.mail,
                          label: 'Email',
                          color: AppColors.info,
                          onTap: () => _launchEmail(context, email),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Booking Info
            Container(
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
                  _infoRow(LucideIcons.calendar, 'Date', _formatDate(booking.scheduledStart)),
                  const Divider(height: 20, color: AppColors.border),
                  _infoRow(LucideIcons.clock, 'Time',
                    '${_formatTime(booking.scheduledStart)} - ${_formatTime(booking.scheduledEnd)}'),
                  const Divider(height: 20, color: AppColors.border),
                  _infoRow(LucideIcons.hourglass, 'Duration', '$totalMinutes min'),
                  const Divider(height: 20, color: AppColors.border),
                  _infoRow(LucideIcons.hash, 'Booking ID', booking.id.substring(0, 8).toUpperCase()),
                  if (booking.staff != null) ...[
                    const Divider(height: 20, color: AppColors.border),
                    _infoRow(LucideIcons.user, 'Staff', booking.staff!['name'] ?? '—'),
                  ],
                  if (booking.customerNotes != null && booking.customerNotes!.isNotEmpty) ...[
                    const Divider(height: 20, color: AppColors.border),
                    _infoRow(LucideIcons.fileText, 'Notes', booking.customerNotes!),
                  ],
                  if (booking.isHomeService && booking.homeServiceAddress != null) ...[
                    const Divider(height: 20, color: AppColors.border),
                    _infoRow(LucideIcons.mapPin, 'Address',
                      '${booking.homeServiceAddress!['street'] ?? ""}, ${booking.homeServiceAddress!['city'] ?? ""}'),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Payment Info
            Container(
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
                  const Text('Payment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 12),
                  _infoRow(LucideIcons.creditCard, 'Method',
                    booking.paymentMethod.isEmpty ? 'Not selected' : booking.paymentMethod.toUpperCase()),
                  const Divider(height: 20, color: AppColors.border),
                  _infoRow(
                    booking.paymentStatus == 'paid' ? LucideIcons.checkCircle : LucideIcons.clock,
                    'Status',
                    booking.paymentStatus == 'paid' ? 'Paid' :
                    booking.paymentStatus == 'initiated' ? 'Processing' :
                    booking.paymentStatus == 'failed' ? 'Failed' : 'Pending',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Services
            Container(
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
                  const Text('Services', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 12),
                  ...booking.services.map((s) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.scissors, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 10),
                        Expanded(child: Text(s.name, style: const TextStyle(fontSize: 13))),
                        Text('${s.durationMinutes} min',
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                        const SizedBox(width: 12),
                        Text('₹${s.price.toInt()}',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      ],
                    ),
                  )),
                  const Divider(height: 24, color: AppColors.border),
                  if (booking.travelCharge > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Text('Travel Charge', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                          const Spacer(),
                          Text('₹${booking.travelCharge.toInt()}',
                            style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                  Row(
                    children: [
                      const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const Spacer(),
                      Text(
                        '₹${total.toInt()}',
                        style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (isPending || isConfirmed || isInProgress || (isCompleted && !isPaid)) ...[
              const SizedBox(height: 24),
              // Action Buttons
              if (isPending)
                Row(
                  children: [
                    Expanded(
                      child: _actionButton(
                        label: 'ACCEPT',
                        color: AppColors.success,
                        onTap: () {
                          context.read<BookingBloc>().add(
                            UpdateBookingStatus(bookingId: booking.id, status: 'confirmed'),
                          );
                          Navigator.pop(context);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _actionButton(
                        label: 'REJECT',
                        color: AppColors.error,
                        outlined: true,
                        onTap: () {
                          context.read<BookingBloc>().add(
                            UpdateBookingStatus(bookingId: booking.id, status: 'cancelled'),
                          );
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ],
                ),
              if (isConfirmed)
                SizedBox(
                  width: double.infinity,
                  child: _actionButton(
                    label: 'START SERVICE',
                    color: AppColors.primary,
                    onTap: () {
                      context.read<BookingBloc>().add(
                        UpdateBookingStatus(bookingId: booking.id, status: 'in_progress'),
                      );
                      Navigator.pop(context);
                    },
                  ),
                ),
              if (isInProgress)
                SizedBox(
                  width: double.infinity,
                  child: _actionButton(
                    label: 'FINISH SERVICE',
                    color: AppColors.success,
                    onTap: () {
                      context.read<BookingBloc>().add(
                        UpdateBookingStatus(bookingId: booking.id, status: 'completed'),
                      );
                      Navigator.pop(context);
                    },
                  ),
                ),
              if (isCompleted && !isPaid)
                SizedBox(
                  width: double.infinity,
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
                      Navigator.pop(context);
                    },
                  ),
                ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _actionChip({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
          ],
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 10),
        SizedBox(
          width: 64,
          child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
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
      return '$h:${dt.minute.toString().padLeft(2, '0')} ${dt.hour >= 12 ? "PM" : "AM"}';
    } catch (_) {
      return '';
    }
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

  Future<void> _launchEmail(BuildContext context, String email) async {
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch email for $email')),
      );
    }
  }
}
