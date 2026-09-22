import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/payment_service.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_state.dart';
import '../bloc/barber_profile/barber_profile_bloc.dart';
import '../bloc/barber_profile/barber_profile_state.dart';
import '../bloc/marketplace/marketplace_bloc.dart';
import '../bloc/marketplace/marketplace_event.dart';
import '../bloc/marketplace/marketplace_state.dart';

class CheckoutScreen extends StatefulWidget {
  final Map<String, dynamic> address;
  final double subTotal;
  final String vendorId;
  final String? couponCode;

  const CheckoutScreen({
    super.key,
    required this.address,
    required this.subTotal,
    required this.vendorId,
    this.couponCode,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _paymentMethod = 'cod';
  bool _isProcessing = false;
  late String _currentOrderNumber;

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final isBarber = authState is AuthAuthenticated && authState.user.role == 'barber';
    final double shipping = (widget.subTotal >= 299 || isBarber) ? 0.0 : 49.0;
    final double total = widget.subTotal + shipping;
    String? businessName;
    String? gstNumber;
    if (isBarber) {
      final barberState = context.read<BarberProfileBloc>().state;
      if (barberState is BarberProfileLoaded) {
        businessName = barberState.profile['shop_name'] as String?;
        gstNumber = barberState.profile['gst_number'] as String?;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        centerTitle: true,
      ),
      body: BlocListener<MarketplaceBloc, MarketplaceState>(
        listener: (context, state) async {
          if (state is MarketplaceLoading) {
            setState(() => _isProcessing = true);
          }
          if (state is OrderCreatedSuccess) {
            _currentOrderNumber = state.order.orderNumber;
            if (_paymentMethod == 'cod') {
              setState(() => _isProcessing = false);
              _showThankYouDialog(_currentOrderNumber);
            } else {
              // Initiate payment in backend
              context.read<MarketplaceBloc>().add(
                InitiateOrderPayment(
                  orderId: state.order.id.toString(),
                  gateway: 'razorpay',
                ),
              );
            }
          }
          if (state is PaymentInitiated) {
            await _openPaymentSheet(state.paymentData);
          }
          if (state is PaymentVerificationSuccess) {
            setState(() => _isProcessing = false);
            _showThankYouDialog(_currentOrderNumber);
          }
          if (state is MarketplaceFailure) {
            setState(() => _isProcessing = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Business Delivery (barber only)
                  if (isBarber) ...[
                    _buildSectionTitle('Business Delivery'),
                    const SizedBox(height: 8),
                    _buildBusinessCard(businessName, gstNumber),
                    const SizedBox(height: 24),
                  ],
                  // Delivery Address Card
                  _buildSectionTitle('Delivery Address'),
                  const SizedBox(height: 8),
                  _buildAddressCard(),
                  const SizedBox(height: 24),

                  // Payment Method Card
                  _buildSectionTitle('Payment Method'),
                  const SizedBox(height: 8),
                  _buildPaymentMethodCard(),
                  const SizedBox(height: 24),

                  // Order Summary Card
                  _buildSectionTitle('Order Summary'),
                  const SizedBox(height: 8),
                  _buildSummaryCard(shipping, total),
                  const SizedBox(height: 32),

                  // Place Order Button
                  ElevatedButton(
                    onPressed: _isProcessing ? null : _placeOrder,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _paymentMethod == 'cod' 
                          ? 'PLACE ORDER (COD)' 
                          : 'PAY & PLACE ORDER',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            if (_isProcessing)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessCard(String? businessName, String? gstNumber) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.building2, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              const Text('BUSINESS DETAILS',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 12),
          Text(businessName ?? 'Salon Name',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          if (gstNumber != null && gstNumber.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('GST: $gstNumber',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.primaryLight,
      ),
    );
  }

  Widget _buildAddressCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.mapPin, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                widget.address['label']?.toString().toUpperCase() ?? 'HOME',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.address['full_name'] ?? '',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            '${widget.address['line_1'] ?? ''}, ${widget.address['line_2'] ?? ''}\n${widget.address['city'] ?? ''}, ${widget.address['state'] ?? ''} - ${widget.address['pincode'] ?? ''}',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 8),
          Text(
            'Phone: ${widget.address['phone'] ?? ''}',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          RadioListTile<String>(
            value: 'cod',
            groupValue: _paymentMethod,
            title: const Text('Cash on Delivery', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            subtitle: const Text('Pay when you receive the order', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            activeColor: AppColors.primary,
            onChanged: (v) {
              if (v != null) setState(() => _paymentMethod = v);
            },
          ),
          const Divider(color: AppColors.border, height: 1),
          RadioListTile<String>(
            value: 'razorpay',
            groupValue: _paymentMethod,
            title: const Text('Online Payment', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            subtitle: const Text('Pay securely via UPI, Card or NetBanking', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            activeColor: AppColors.primary,
            onChanged: (v) {
              if (v != null) setState(() => _paymentMethod = v);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(double shipping, double total) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Items Subtotal', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              Text('₹${widget.subTotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Delivery Charges', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              if (shipping == 0)
                Row(
                  children: [
                    const Text('₹50.00', style: TextStyle(color: AppColors.textMuted, fontSize: 12, decoration: TextDecoration.lineThrough)),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('FREE', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 11)),
                    ),
                  ],
                )
              else
                Text('₹${shipping.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
          const Divider(color: AppColors.border, height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Payable', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Text(
                '₹${total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _placeOrder() {
    setState(() => _isProcessing = true);
    context.read<MarketplaceBloc>().add(
      PlaceOrder(
        vendorId: widget.vendorId,
        shippingAddressId: widget.address['id'].toString(),
        couponCode: widget.couponCode,
        paymentMethod: _paymentMethod,
      ),
    );
  }

  Future<void> _openPaymentSheet(Map<String, dynamic> paymentData) async {
    final paymentService = PaymentService();
    final result = await paymentService.presentPaymentSheet(
      context: context,
      amount: (paymentData['amount'] as num).toDouble() / 100,
      currency: 'INR',
      razorpayKey: paymentData['key_id'] as String,
      orderId: paymentData['gateway_order_id'] as String,
      customerName: widget.address['full_name'] ?? 'Customer',
      customerEmail: 'customer@barbar.app',
      customerPhone: widget.address['phone'] ?? '',
    );
    paymentService.dispose();

    if (!mounted) return;

    if (result.success) {
      final paymentId = paymentData['payment_id'] as String;
      context.read<MarketplaceBloc>().add(
        VerifyOrderPayment(
          paymentId: paymentId,
          gateway: 'razorpay',
          razorpayOrderId: result.razorpayOrderId ?? '',
          razorpayPaymentId: result.razorpayPaymentId ?? '',
          razorpaySignature: result.razorpaySignature ?? '',
        ),
      );
    } else {
      setState(() => _isProcessing = false);
      _showPaymentFailedDialog(_currentOrderNumber);
    }
  }

  void _showPaymentFailedDialog(String orderNumber) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: const Row(
          children: [
            Icon(LucideIcons.alertTriangle, color: AppColors.error),
            SizedBox(width: 8),
            Text('Payment Failed', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(
          'Your payment was cancelled or failed. However, your order #$orderNumber has been created in pending payment status. You can retry paying from your Booking/Order History.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              Navigator.pop(dialogCtx);
              Navigator.pop(context, true); // Close checkout screen
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showThankYouDialog(String orderNumber) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => Dialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.success.withOpacity(0.3), width: 2),
                ),
                child: const Icon(
                  LucideIcons.check,
                  color: AppColors.success,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Thank You!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your order has been placed successfully.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: () {
                  Navigator.pop(dialogCtx); // Close Thank You Dialog
                  Navigator.pop(context, true); // Close Checkout Screen, returning to Shop Screen
                },
                child: const Text(
                  'CONTINUE SHOPPING',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
