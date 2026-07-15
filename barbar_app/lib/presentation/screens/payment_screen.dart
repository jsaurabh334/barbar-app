import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/services/payment_service.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/booking_model.dart';
import '../bloc/booking/booking_bloc.dart';
import '../bloc/booking/booking_event.dart';
import '../bloc/booking/booking_state.dart';
import '../widgets/glass_card.dart';
import 'invoice_screen.dart';

class PaymentScreen extends StatefulWidget {
  final BookingModel booking;

  const PaymentScreen({super.key, required this.booking});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _selectedMethod = 'upi';
  bool _isProcessing = false;
  bool _cashConfirmed = false;
  Map<String, dynamic>? _paymentData;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BookingBloc, BookingState>(
      listener: (context, state) {
        if (state is BookingPaymentInitiated) {
          _paymentData = state.paymentData;
          _openPaymentSheet(state.paymentData);
        } else if (state is BookingPaymentVerified) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Payment successful!'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => InvoiceScreen(bookingId: widget.booking.id),
            ),
          );
        } else if (state is BookingsLoaded && _cashConfirmed) {
          if (!mounted) return;
          Navigator.pop(context, true);
        } else if (state is BookingFailure) {
          setState(() => _isProcessing = false);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('SELECT PAYMENT METHOD'),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'BILL DETAILS',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                      ),
                      const Divider(height: 24, color: AppColors.border),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Booking ID:', style: TextStyle(color: AppColors.textSecondary)),
                          Text('#${widget.booking.id.substring(0, 8)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Amount:', style: TextStyle(color: AppColors.textSecondary)),
                          Text(
                            '₹${widget.booking.finalPrice.toInt()}',
                            style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primary, fontSize: 20),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'PAYMENT OPTIONS',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                
                _buildPaymentMethodTile(
                  id: 'upi',
                  title: 'UPI (Paytm, PhonePe, GPay)',
                  subtitle: 'Pay online via Razorpay',
                  icon: LucideIcons.qrCode,
                ),
                const SizedBox(height: 16),
                
                _buildPaymentMethodTile(
                  id: 'cash',
                  title: 'Cash Payment',
                  subtitle: 'Pay at the counter after service — barber will collect',
                  icon: LucideIcons.banknote,
                ),
                const SizedBox(height: 32),

                if (_selectedMethod == 'upi') ...[
                  Center(
                    child: GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Container(
                            width: 180,
                            height: 180,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              LucideIcons.qrCode,
                              size: 140,
                              color: AppColors.surface,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Scan to Pay using any UPI App',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _isProcessing ? null : _initiateUPIPayment,
                    child: _isProcessing
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('PAY NOW'),
                  ),
                ],

                if (_selectedMethod == 'cash')
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.info.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(LucideIcons.info, color: AppColors.info, size: 20),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Pay at the counter after service. The barber will mark the payment as received.',
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: _isProcessing ? null : _confirmCashPayment,
                        child: _isProcessing
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text('CONFIRM CASH PAYMENT'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _initiateUPIPayment() {
    setState(() => _isProcessing = true);
    context.read<BookingBloc>().add(
      InitiateBookingPayment(
        bookingId: widget.booking.id,
        gateway: 'razorpay',
      ),
    );
  }

  void _confirmCashPayment() {
    setState(() {
      _isProcessing = true;
      _cashConfirmed = true;
    });
    context.read<BookingBloc>().add(
      PayBooking(
        bookingId: widget.booking.id,
        method: 'cash',
        status: 'pending',
        reference: '',
      ),
    );
  }

  Future<void> _openPaymentSheet(Map<String, dynamic> paymentData) async {
    final paymentService = PaymentService();
    final result = await paymentService.presentPaymentSheet(
      context: context,
      amount: (paymentData['amount'] as num).toDouble() / 100,
      currency: 'INR',
    );

    if (!mounted) return;

    if (result.success) {
      final gatewayOrderId = paymentData['gateway_order_id'] as String;
      final paymentId = paymentData['payment_id'] as String;
      final mockPaymentId = result.transactionId ?? 'mock_pay_${DateTime.now().millisecondsSinceEpoch}';

      context.read<BookingBloc>().add(
        VerifyBookingPayment(
          paymentId: paymentId,
          gateway: 'razorpay',
          razorpayOrderId: gatewayOrderId,
          razorpayPaymentId: mockPaymentId,
          razorpaySignature: 'dev_mode_skip_verify',
        ),
      );
    } else {
      setState(() => _isProcessing = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorMessage ?? 'Payment cancelled'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Widget _buildPaymentMethodTile({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _selectedMethod == id;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMethod = id;
          _cashConfirmed = false;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : AppColors.textSecondary, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
            ),
            Icon(
              isSelected ? LucideIcons.checkCircle : LucideIcons.circle,
              color: isSelected ? AppColors.primary : AppColors.border,
            ),
          ],
        ),
      ),
    );
  }
}
