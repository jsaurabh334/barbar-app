import 'dart:async';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

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
        'description': 'Barbar App',
        'order_id': orderId,
        'prefill': {
          'contact': customerPhone,
          'email': customerEmail,
        },
        'theme': {
          'color': '#E0245E',
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

  void dispose() {
    _razorpay?.clear();
  }
}
