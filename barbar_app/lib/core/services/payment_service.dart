import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../theme/app_theme.dart';

class PaymentResult {
  final bool success;
  final String? razorpayPaymentId;
  final String? razorpayOrderId;
  final String? razorpaySignature;
  final String? errorMessage;

  PaymentResult({
    required this.success,
    this.razorpayPaymentId,
    this.razorpayOrderId,
    this.razorpaySignature,
    this.errorMessage,
  });
}

class PaymentService {
  Razorpay? _razorpay;

  Future<PaymentResult> presentPaymentSheet({
    required BuildContext context,
    required double amount,
    required String currency,
    required String razorpayKey,
    required String orderId,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
  }) async {
    // If running in development / test with dummy keys or mock order, show interactive payment gateway simulator
    final isMock = razorpayKey.isEmpty ||
        razorpayKey.contains('dummy') ||
        orderId.startsWith('order_mock_');

    if (isMock) {
      return _showPaymentSimulationSheet(
        context: context,
        amount: amount,
        currency: currency,
        orderId: orderId,
        customerName: customerName,
      );
    }

    final completer = Completer<PaymentResult>();

    _razorpay = Razorpay();

    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, (response) {
      completer.complete(PaymentResult(
        success: true,
        razorpayPaymentId: response['razorpay_payment_id'],
        razorpayOrderId: response['razorpay_order_id'],
        razorpaySignature: response['razorpay_signature'],
      ));
    });

    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, (response) {
      completer.complete(PaymentResult(
        success: false,
        errorMessage: response['error']?['description'] ?? 'Payment failed',
      ));
    });

    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, (response) {
      completer.complete(PaymentResult(
        success: true,
        razorpayPaymentId: response['payment_id'],
        razorpayOrderId: response['order_id'],
        razorpaySignature: response['signature'],
      ));
    });

    try {
      _razorpay!.open({
        'key': razorpayKey,
        'amount': (amount * 100).toInt(),
        'name': customerName,
        'description': 'Barbar App Order',
        'order_id': orderId,
        'prefill': {
          'contact': customerPhone,
          'email': customerEmail,
        },
        'theme': {
          'color': '#F5A623',
        },
      });
    } catch (e) {
      completer.complete(PaymentResult(
        success: false,
        errorMessage: e.toString(),
      ));
    }

    return completer.future;
  }

  Future<PaymentResult> _showPaymentSimulationSheet({
    required BuildContext context,
    required double amount,
    required String currency,
    required String orderId,
    required String customerName,
  }) async {
    String selectedMethod = 'upi_gpay';

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          return Container(
            decoration: const BoxDecoration(
              color: Color(0xFF161622),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(LucideIcons.creditCard, color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Razorpay Secure Gateway',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Test Mode Simulation',
                            style: GoogleFonts.outfit(color: AppColors.warning, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '₹${amount.toStringAsFixed(0)}',
                        style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'SELECT PAYMENT METHOD',
                  style: GoogleFonts.outfit(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
                const SizedBox(height: 10),
                _buildMethodOption(
                  id: 'upi_gpay',
                  title: 'Google Pay / UPI',
                  subtitle: 'Fast UPI Payment',
                  icon: LucideIcons.smartphone,
                  selected: selectedMethod == 'upi_gpay',
                  onTap: () => setState(() => selectedMethod = 'upi_gpay'),
                ),
                _buildMethodOption(
                  id: 'upi_phonepe',
                  title: 'PhonePe / Paytm UPI',
                  subtitle: 'Direct UPI transfer',
                  icon: LucideIcons.zap,
                  selected: selectedMethod == 'upi_phonepe',
                  onTap: () => setState(() => selectedMethod = 'upi_phonepe'),
                ),
                _buildMethodOption(
                  id: 'card',
                  title: 'Debit / Credit Card',
                  subtitle: 'Visa, MasterCard, RuPay',
                  icon: LucideIcons.creditCard,
                  selected: selectedMethod == 'card',
                  onTap: () => setState(() => selectedMethod = 'card'),
                ),
                _buildMethodOption(
                  id: 'netbanking',
                  title: 'Net Banking',
                  subtitle: 'All Major Indian Banks',
                  icon: LucideIcons.landmark,
                  selected: selectedMethod == 'netbanking',
                  onTap: () => setState(() => selectedMethod = 'netbanking'),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(
                    'PAY ₹${amount.toStringAsFixed(0)} (Simulate Success)',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(
                    'Cancel Payment',
                    style: GoogleFonts.outfit(color: Colors.white54, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    if (result == true) {
      final now = DateTime.now().millisecondsSinceEpoch;
      return PaymentResult(
        success: true,
        razorpayPaymentId: 'pay_sim_$now',
        razorpayOrderId: orderId,
        razorpaySignature: 'sig_sim_$now',
      );
    } else {
      return PaymentResult(
        success: false,
        errorMessage: 'Payment cancelled by user',
      );
    }
  }

  Widget _buildMethodOption({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.12) : const Color(0xFF1E1E2E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.white10,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? AppColors.primary : Colors.white60, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(color: Colors.white54, fontSize: 11),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(LucideIcons.checkCircle2, color: AppColors.primary, size: 18)
            else
              const Icon(LucideIcons.circle, color: Colors.white24, size: 18),
          ],
        ),
      ),
    );
  }

  void dispose() {
    _razorpay?.clear();
  }
}
