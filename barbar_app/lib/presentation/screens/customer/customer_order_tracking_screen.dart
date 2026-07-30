import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/websocket_client.dart';
import '../../../data/models/tracking/tracking_response.dart';
import '../../../data/repositories/tracking_repository_impl.dart';
import '../../../domain/repositories/tracking_repository.dart';
import '../../widgets/tracking/driver_card_widget.dart';
import '../../widgets/tracking/timeline_widget.dart';
import '../../widgets/tracking/tracking_map_widget.dart';

import '../../../data/models/order_model.dart';

class CustomerOrderTrackingScreen extends StatefulWidget {
  final String orderId;
  final OrderModel? order;

  const CustomerOrderTrackingScreen({super.key, required this.orderId, this.order});

  @override
  State<CustomerOrderTrackingScreen> createState() => _CustomerOrderTrackingScreenState();
}

class _CustomerOrderTrackingScreenState extends State<CustomerOrderTrackingScreen> {
  TrackingRepository? _repository;
  StreamSubscription<TrackingResponse>? _sub;
  TrackingResponse? _response;
  bool _isLoading = true;
  bool _isLive = true;
  String? _error;
  Timer? _timeoutTimer;
  static const Duration _timeoutDuration = Duration(seconds: 10);

  @override
  void initState() {
    super.initState();
    _startTracking();
  }

  void _startTracking() {
    _repository?.dispose();
    _sub?.cancel();
    _timeoutTimer?.cancel();

    final apiClient = context.read<ApiClient>();
    final wsClient = context.read<WebSocketClient>();
    _repository = TrackingRepositoryImpl(apiClient, wsClient);

    setState(() {
      _isLoading = true;
      _error = null;
      _response = null;
      _isLive = true;
    });

    _timeoutTimer = Timer(_timeoutDuration, () {
      if (mounted) {
        _sub?.cancel();
        _repository?.dispose();
        setState(() {
          _isLoading = false;
          _error = 'Unable to load tracking. Please try again.';
        });
      }
    });

    _sub = _repository!.trackingUpdates(widget.orderId).listen(
      (response) {
        _timeoutTimer?.cancel();
        if (mounted) {
          setState(() {
            _response = response;
            _isLoading = false;
            _isLive = true;
          });
        }
      },
      onError: (err) {
        _timeoutTimer?.cancel();
        if (mounted) {
          setState(() {
            _isLoading = false;
            _error = err.toString();
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _sub?.cancel();
    _repository?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Tracking'),
        actions: [
          if (!_isLoading && _response != null && !_isLive)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.wifiOff, size: 14, color: AppColors.warning),
                  SizedBox(width: 4),
                  Text('Offline', style: TextStyle(fontSize: 11, color: AppColors.warning)),
                ],
              ),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text('Getting driver location...',
                style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    if (_error != null && _response == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.map, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 12),
            const Text('Unable to load tracking details',
                style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Text(_error!, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _startTracking,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Retry', style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      );
    }

    final response = _response;
    if (response == null) return const SizedBox.shrink();

    final status = response.status.toLowerCase();

    if (_isLiveTrackingStatus(status)) {
      return _buildLiveTrackingView(response, status);
    }

    return _buildStaticView(response, status);
  }

  bool _isLiveTrackingStatus(String status) {
    return status == 'driver_assigned' ||
        status == 'driver_accepted' ||
        status == 'picked_up' ||
        status == 'out_for_delivery';
  }

  Widget _buildLiveTrackingView(TrackingResponse response, String status) {
    return Column(
      children: [
        Expanded(
          flex: 5,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: TrackingMapWidget(response: response),
          ),
        ),
        Expanded(
          flex: 5,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildEtaBar(response),
                const SizedBox(height: 12),
                if (response.deliveryOtp != null && status == 'picked_up')
                  _buildOtpCard(response.deliveryOtp!),
                if (response.driver != null) ...[
                  const SizedBox(height: 12),
                  DriverCardWidget(driver: response.driver!),
                ],
                const SizedBox(height: 12),
                TimelineWidget(
                  entries: response.timeline,
                  currentStatus: response.status,
                ),
                const SizedBox(height: 8),
                if (!_isLive)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.wifiOff, size: 14, color: AppColors.warning),
                        SizedBox(width: 6),
                        Text(
                          'Driver location unavailable. Retrying...',
                          style: TextStyle(fontSize: 11, color: AppColors.warning),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStaticView(TrackingResponse response, String status) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildStatusHeaderBanner(response),
          if (status == 'ready_for_pickup' && response.eta != null) ...[
            const SizedBox(height: 12),
            _buildEtaBar(response),
          ],
          if (status == 'delivered' && response.driver != null) ...[
            const SizedBox(height: 12),
            DriverCardWidget(driver: response.driver!),
          ],
          const SizedBox(height: 12),
          _buildOrderDetailsCard(),
          const SizedBox(height: 12),
          TimelineWidget(
            entries: response.timeline,
            currentStatus: response.status,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDetailsCard() {
    final order = widget.order;
    if (order == null) return const SizedBox.shrink();

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
          const Row(
            children: [
              Icon(LucideIcons.shoppingBag, color: AppColors.primary, size: 18),
              SizedBox(width: 8),
              Text('Order Items', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 12),
          if (order.items != null)
            ...order.items!.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Text('${item.quantity}x', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(item.productName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                      ),
                      Text('₹${(item.price * item.quantity).toInt()}', style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                )),
          const Divider(color: AppColors.border, height: 24),
          _priceRow('Subtotal', '₹${order.itemsTotal.toInt()}'),
          const SizedBox(height: 6),
          _priceRow('Delivery Fee', '₹${order.shippingCharge.toInt()}'),
          const Divider(color: AppColors.border, height: 24),
          _priceRow('Total Bill', '₹${order.finalAmount.toInt()}', isBold: true, color: AppColors.primary, fontSize: 16),
          const Divider(color: AppColors.border, height: 24),
          Row(
            children: [
              const Icon(LucideIcons.creditCard, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text('Payment: ${(order.paymentMethod ?? "N/A").toUpperCase()}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const Spacer(),
              Text(
                order.paymentStatus.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: order.paymentStatus == 'paid' || order.paymentStatus == 'completed'
                      ? AppColors.success
                      : AppColors.warning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _priceRow(String label, String value, {bool isBold = false, Color? color, double fontSize = 13}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: isBold ? Colors.white : AppColors.textSecondary, fontSize: fontSize, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        Text(value, style: TextStyle(color: color ?? Colors.white, fontWeight: isBold ? FontWeight.bold : FontWeight.w600, fontSize: fontSize)),
      ],
    );
  }

  Widget _buildStatusHeaderBanner(TrackingResponse response) {
    final status = response.status.toLowerCase();
    IconData icon;
    Color color;
    String title;
    String subtitle;

    switch (status) {
      case 'pending':
        icon = LucideIcons.clock;
        color = AppColors.warning;
        title = 'Order Received';
        subtitle = 'Waiting for vendor to accept your order.';
        break;
      case 'confirmed':
      case 'accepted':
        icon = LucideIcons.checkCircle;
        color = AppColors.info;
        title = 'Order Confirmed';
        subtitle = 'Vendor has accepted and is preparing your order.';
        break;
      case 'preparing':
      case 'packed':
        icon = LucideIcons.package;
        color = AppColors.primary;
        title = 'Preparing Order';
        subtitle = 'Your items are being packed and readied for dispatch.';
        break;
      case 'ready_for_pickup':
        icon = LucideIcons.store;
        color = AppColors.primary;
        title = 'Ready for Pickup';
        subtitle = 'Order is packed. Finding a delivery partner...';
        break;
      case 'delivered':
        icon = LucideIcons.checkCircle2;
        color = AppColors.success;
        title = 'Order Delivered';
        subtitle = 'Thank you for ordering with us!';
        break;
      case 'cancelled':
        icon = LucideIcons.xCircle;
        color = AppColors.error;
        title = 'Order Cancelled';
        subtitle = 'This order has been cancelled.';
        break;
      default:
        icon = LucideIcons.info;
        color = AppColors.primary;
        title = response.status.toUpperCase();
        subtitle = 'Order status update.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEtaBar(TrackingResponse response) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(LucideIcons.navigation, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ETA ${response.eta?.minutes.toStringAsFixed(0) ?? '--'} min',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${response.eta?.distanceKm.toStringAsFixed(1) ?? '--'} km · ${_statusLabel(response.status)}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Text(
            '#${widget.orderId.length > 8 ? widget.orderId.substring(0, 8) : widget.orderId}',
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpCard(String otp) {
    final expiresSec = _response?.expiresInSeconds;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.shieldCheck, color: Colors.green.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                'Delivery OTP',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.green.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            otp,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 32,
              letterSpacing: 12,
              color: Colors.green.shade900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Share this code with the delivery driver',
            style: TextStyle(fontSize: 12, color: Colors.green.shade600),
          ),
          if (expiresSec != null) ...[
            const SizedBox(height: 8),
            Text(
              'Expires in ${_formatDuration(expiresSec)}',
              style: TextStyle(fontSize: 11, color: Colors.green.shade500),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final min = seconds ~/ 60;
    final sec = seconds % 60;
    if (min > 0) return '$min min ${sec}s';
    return '${sec}s';
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending': return 'Order Placed';
      case 'accepted': return 'Accepted';
      case 'packed': return 'Packed';
      case 'ready_for_pickup': return 'Ready';
      case 'driver_assigned': return 'Finding Driver';
      case 'driver_accepted': return 'Driver En Route';
      case 'picked_up': return 'Picked Up';
      case 'out_for_delivery': return 'Out for Delivery';
      case 'delivered': return 'Delivered';
      case 'cancelled': return 'Cancelled';
      default: return status.replaceAll('_', ' ');
    }
  }
}
