import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PaymentResult {
  final bool success;
  final String? transactionId;
  final String? errorMessage;

  PaymentResult({required this.success, this.transactionId, this.errorMessage});
}

class PaymentService {
  Future<PaymentResult> presentPaymentSheet({
    required BuildContext context,
    required double amount,
    required String currency,
  }) async {
    // Show a beautiful custom processing dialog replicating Razorpay Payment Sheet
    final result = await showGeneralDialog<PaymentResult>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'RazorpayPaymentSheet',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            height: 380,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'RAZORPAY SECURE CHECKOUT',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.5, color: Colors.white60),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white60),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Razorpay',
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24, color: AppColors.border),
                    const SizedBox(height: 12),
                    Text(
                      'Pay Barbar Platform',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Amount due: ${currency.toUpperCase()} ${amount.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primary, fontSize: 16),
                    ),
                    const SizedBox(height: 32),
                    
                    // Card Mock Display
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.credit_card, color: AppColors.primary),
                          SizedBox(width: 16),
                          Text('•••• •••• •••• 4242', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                          Spacer(),
                          Text('12/29', style: TextStyle(color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    const Spacer(),
                    
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3399CC), // Razorpay Teal/Blue
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        // Show loading indicator inside button mock
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (c) => const Center(child: CircularProgressIndicator(color: Colors.white)),
                        );
                        await Future.delayed(const Duration(seconds: 2));
                        if (!context.mounted) return;
                        Navigator.pop(context); // Pop loading
                        Navigator.pop(
                          context,
                          PaymentResult(
                            success: true,
                            transactionId: 'pay_razorpay_${DateTime.now().millisecondsSinceEpoch}',
                          ),
                        );
                      },
                      child: const Text('PAY SECURELY NOW'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context, PaymentResult(success: false, errorMessage: 'Payment cancelled by user.'));
                      },
                      child: const Text('CANCEL PAYMENT', style: TextStyle(color: AppColors.textSecondary)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
    
    return result ?? PaymentResult(success: false, errorMessage: 'Unknown checkout failure.');
  }
}
