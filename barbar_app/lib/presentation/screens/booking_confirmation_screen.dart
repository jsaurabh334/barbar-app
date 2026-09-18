import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/network/websocket_client.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/booking_model.dart';
import '../bloc/booking/booking_bloc.dart';
import '../bloc/booking/booking_event.dart';
import 'customer_dashboard_shell.dart';

class BookingConfirmationScreen extends StatefulWidget {
  final BookingModel booking;
  final String shopName;

  const BookingConfirmationScreen({
    super.key,
    required this.booking,
    required this.shopName,
  });

  @override
  State<BookingConfirmationScreen> createState() =>
      _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen>
    with TickerProviderStateMixin {
  late AnimationController _iconController;
  late AnimationController _contentController;
  late Animation<double> _iconScale;
  late Animation<double> _iconFade;
  late Animation<double> _contentFade;
  late Animation<Offset> _contentSlide;

  static const _autoRedirectSeconds = 4;
  int _countdown = _autoRedirectSeconds;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();

    // Icon animation: scale from 0 → 1.2 → 1.0 with bounce
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _iconScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.25), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.25, end: 0.9), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.0), weight: 20),
    ]).animate(CurvedAnimation(parent: _iconController, curve: Curves.easeOut));
    _iconFade = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _iconController, curve: const Interval(0, 0.5)),
    );

    // Content animation: fade + slide up
    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _contentFade = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeOut),
    );
    _contentSlide = Tween(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeOut),
    );

    // Start animations and sound
    _playEntrance();
  }

  Future<void> _playEntrance() async {
    // Play success sound + haptic
    HapticFeedback.mediumImpact();
    SystemSound.play(SystemSoundType.click);

    // Start icon animation
    await _iconController.forward();

    // Then content slides in
    _contentController.forward();

    // Start auto-redirect countdown
    _startCountdown();
  }

  void _startCountdown() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted || _hasNavigated) return false;
      setState(() => _countdown--);
      if (_countdown <= 0) {
        _navigateToBookings();
        return false;
      }
      return true;
    });
  }

  void _navigateToBookings() {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;
    context.read<BookingBloc>().add(FetchAllBookings());
    final wsClient = context.read<WebSocketClient>();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => CustomerDashboardShell(
          webSocketClient: wsClient,
          initialTab: 2,
        ),
      ),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _iconController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double total = 0;
    for (final s in widget.booking.services) {
      total += s.price;
    }
    total += widget.booking.travelCharge;

    final isPending = widget.booking.status == 'pending' ||
        widget.booking.status == 'home_service_pending';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),

              // Animated Success Icon
              AnimatedBuilder(
                animation: _iconController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _iconFade.value.clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: _iconScale.value,
                      child: child,
                    ),
                  );
                },
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: (isPending ? AppColors.warning : AppColors.success)
                        .withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: (isPending ? AppColors.warning : AppColors.success)
                          .withValues(alpha: 0.4),
                      width: 2.5,
                    ),
                  ),
                  child: Icon(
                    isPending ? LucideIcons.clock : LucideIcons.checkCircle,
                    size: 48,
                    color: isPending ? AppColors.warning : AppColors.success,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Animated Content
              FadeTransition(
                opacity: _contentFade,
                child: SlideTransition(
                  position: _contentSlide,
                  child: Column(
                    children: [
                      Text(
                        isPending ? 'Booking Requested' : 'Booking Confirmed!',
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isPending
                            ? 'Your request has been sent to the shop.\nWe\'ll notify you once the barber accepts it.'
                            : 'Your booking is confirmed.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 14),
                      ),
                      const SizedBox(height: 12),

                      // Auto-redirect countdown
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Redirecting to My Bookings in $_countdown...',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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
                            _detailRow(
                                widget.booking.isHomeService
                                    ? LucideIcons.home
                                    : LucideIcons.store,
                                'Type',
                                widget.booking.isHomeService
                                    ? 'Home Service'
                                    : 'Visit Shop'),
                            const Divider(
                                height: 24, color: AppColors.border),
                            if (widget.booking.isHomeService) ...[
                              if (widget.booking.homeServiceAddress != null)
                                _detailRow(
                                    LucideIcons.mapPin,
                                    'Address',
                                    [
                                      widget.booking
                                          .homeServiceAddress!['street'],
                                      widget
                                          .booking.homeServiceAddress!['city']
                                    ]
                                        .where((e) =>
                                            e != null &&
                                            e.toString().trim().isNotEmpty)
                                        .join(', ')),
                              if (widget.booking.travelDistanceKm > 0)
                                _detailRow(LucideIcons.map, 'Distance',
                                    '${widget.booking.travelDistanceKm.toStringAsFixed(1)} km'),
                              if (widget.booking.travelCharge > 0)
                                _detailRow(LucideIcons.indianRupee, 'Travel',
                                    '₹${widget.booking.travelCharge.toInt()}'),
                              const Divider(
                                  height: 24, color: AppColors.border),
                            ],
                            _detailRow(
                                LucideIcons.store, 'Shop', widget.shopName),
                            const Divider(
                                height: 24, color: AppColors.border),
                            if (widget.booking.staff != null)
                              _detailRow(
                                  LucideIcons.user,
                                  'Professional',
                                  widget.booking.staff!['name'] ??
                                      'Assigned'),
                            if (widget.booking.staff != null)
                              const Divider(
                                  height: 24, color: AppColors.border),
                            _detailRow(LucideIcons.calendar, 'Date',
                                _formatDate(widget.booking.scheduledStart)),
                            const Divider(
                                height: 24, color: AppColors.border),
                            _detailRow(LucideIcons.clock, 'Time',
                                _formatTime(widget.booking.scheduledStart)),
                            const Divider(
                                height: 24, color: AppColors.border),
                            _detailRow(
                                LucideIcons.hash,
                                'Booking ID',
                                widget.booking.id
                                    .substring(0, 8)
                                    .toUpperCase()),
                            const Divider(
                                height: 24, color: AppColors.border),

                            // Services
                            const Text('Services',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15)),
                            const SizedBox(height: 8),
                            ...widget.booking.services.map((s) => Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      const Icon(LucideIcons.scissors,
                                          size: 14,
                                          color: AppColors.textSecondary),
                                      const SizedBox(width: 8),
                                      Expanded(
                                          child: Text(s.name,
                                              style: const TextStyle(
                                                  fontSize: 13))),
                                      Text('₹${s.price.toInt()}',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13)),
                                    ],
                                  ),
                                )),
                            const Divider(
                                height: 24, color: AppColors.border),

                            // Total
                            Row(
                              children: [
                                const Text('Total',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
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

                      // Go to My Bookings Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: _navigateToBookings,
                          child: const Text(
                            'Go to My Bookings',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 10),
        SizedBox(
          width: 90,
          child: Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13)),
        ),
        Expanded(
          child: Text(value,
              style:
                  const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
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
