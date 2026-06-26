import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../../presentation/screens/wallet_screen.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  Future<void> initialize(BuildContext context) async {
    // Replicate Firebase Cloud Messaging token generation and initialization
    // For test simulations, print token
    debugPrint('FCM TOKEN generated: fcm_device_token_barbar_${DateTime.now().millisecondsSinceEpoch}');
  }

  void handleDeepLink({
    required BuildContext context,
    required String urlScheme,
  }) {
    // Parse deep links matching section 8.1
    // Schemes: barbar://bookings/:id, barbar://orders/:id, barbar://wallet
    final uri = Uri.parse(urlScheme);
    if (uri.scheme != 'barbar') return;

    final pathSegments = uri.pathSegments;
    if (pathSegments.isEmpty) return;

    final module = pathSegments.first;
    
    if (module == 'bookings' && pathSegments.length > 1) {
      final bookingId = pathSegments[1];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Navigating to live queue booking ID: $bookingId'),
          backgroundColor: AppColors.primary,
        ),
      );
    } else if (module == 'orders' && pathSegments.length > 1) {
      final orderId = pathSegments[1];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Navigating to marketplace order ID: $orderId'),
          backgroundColor: AppColors.primary,
        ),
      );
    } else if (module == 'wallet') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (c) => const WalletScreen()),
      );
    }
  }

  // Helper mock function to simulate receiving an FCM push notification while app is running
  void simulateIncomingFcmMessage({
    required BuildContext context,
    required String title,
    required String body,
    required String linkUrl,
  }) {
    // Show premium overlay banner
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 5),
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        margin: const EdgeInsets.all(16),
        behavior: SnackBarBehavior.floating,
        content: Row(
          children: [
            const Icon(Icons.notifications_active, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 2),
                  Text(body, style: const TextStyle(fontSize: 12, color: Colors.white70)),
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                handleDeepLink(context: context, urlScheme: linkUrl);
              },
              child: const Text('VIEW', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
