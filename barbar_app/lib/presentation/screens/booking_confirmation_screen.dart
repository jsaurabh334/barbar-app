import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/booking_model.dart';

class BookingConfirmationScreen extends StatelessWidget {
  final BookingModel booking;
  final String shopName;

  const BookingConfirmationScreen({
    super.key,
    required this.booking,
    required this.shopName,
  });

  @override
  Widget build(BuildContext context) {
    double total = 0;
    for (final s in booking.services) {
      total += s.price;
    }
    total += booking.travelCharge;

    final isPending = booking.status == 'pending' || booking.status == 'home_service_pending';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: (isPending ? AppColors.warning : AppColors.success).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPending ? LucideIcons.clock : LucideIcons.checkCircle,
                  size: 48,
                  color: isPending ? AppColors.warning : AppColors.success,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isPending ? 'Booking Requested' : 'Booking Confirmed!',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(
                isPending
                    ? 'Your request has been sent to the shop.\nWe\'ll notify you once the barber accepts it.'
                    : 'Your booking is confirmed.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 32),

              // Booking Details Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _detailRow(booking.isHomeService ? LucideIcons.home : LucideIcons.store, 'Type', booking.isHomeService ? 'Home Service' : 'Visit Shop'),
                    const Divider(height: 24, color: AppColors.border),
                    if (booking.isHomeService) ...[
                      if (booking.homeServiceAddress != null)
                        _detailRow(LucideIcons.mapPin, 'Address',
                          '${booking.homeServiceAddress!['street'] ?? ""}, ${booking.homeServiceAddress!['city'] ?? ""}'),
                      if (booking.travelDistanceKm > 0)
                        _detailRow(LucideIcons.map, 'Distance', '${booking.travelDistanceKm.toStringAsFixed(1)} km'),
                      if (booking.travelCharge > 0)
                        _detailRow(LucideIcons.indianRupee, 'Travel', '₹${booking.travelCharge.toInt()}'),
                      const Divider(height: 24, color: AppColors.border),
                    ],
                    _detailRow(LucideIcons.store, 'Shop', shopName),
                    const Divider(height: 24, color: AppColors.border),
                    if (booking.staff != null)
                      _detailRow(LucideIcons.user, 'Professional', booking.staff!['name'] ?? 'Assigned'),
                    if (booking.staff != null) const Divider(height: 24, color: AppColors.border),
                    _detailRow(LucideIcons.calendar, 'Date', _formatDate(booking.scheduledStart)),
                    const Divider(height: 24, color: AppColors.border),
                    _detailRow(LucideIcons.clock, 'Time', _formatTime(booking.scheduledStart)),
                    const Divider(height: 24, color: AppColors.border),
                    _detailRow(LucideIcons.hash, 'Booking ID', booking.id.substring(0, 8).toUpperCase()),
                    const Divider(height: 24, color: AppColors.border),

                    // Services
                    const Text('Services', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    const SizedBox(height: 8),
                    ...booking.services.map((s) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.scissors, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 8),
                          Expanded(child: Text(s.name, style: const TextStyle(fontSize: 13))),
                          Text('₹${s.price.toInt()}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        ],
                      ),
                    )),
                    const Divider(height: 24, color: AppColors.border),

                    // Total
                    Row(
                      children: [
                        const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const Spacer(),
                        Text(
                          '₹${total.toInt()}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Main Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () {
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  child: Text(
                    isPending ? 'View Booking Status' : 'Track Queue',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('My Bookings'),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
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
}
