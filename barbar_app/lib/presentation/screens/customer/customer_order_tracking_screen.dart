import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/websocket_client.dart';
import '../../../data/models/tracking/tracking_response.dart';
import '../../../data/repositories/tracking_repository_impl.dart';
import '../../../domain/repositories/tracking_repository.dart';
import '../../widgets/tracking/driver_card_widget.dart';
import '../../widgets/tracking/timeline_widget.dart';
import '../../widgets/tracking/tracking_map_widget.dart';

class CustomerOrderTrackingScreen extends StatefulWidget {
  final String orderId;

  const CustomerOrderTrackingScreen({super.key, required this.orderId});

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

  @override
  void initState() {
    super.initState();
    _startTracking();
  }

  void _startTracking() {
    _repository?.dispose();
    _sub?.cancel();

    final apiClient = ApiClient();
    final wsClient = WebSocketClient();
    _repository = TrackingRepositoryImpl(apiClient, wsClient);

    setState(() {
      _isLoading = true;
      _error = null;
    });

    _sub = _repository!.trackingUpdates(widget.orderId).listen(
      (response) {
        if (mounted) {
          setState(() {
            _response = response;
            _isLoading = false;
            _isLive = true;
          });
        }
      },
      onError: (err) {
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
            const Text('Driver location unavailable',
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
                if (response.deliveryOtp != null) ...[
                  _buildOtpCard(response.deliveryOtp!),
                  const SizedBox(height: 12),
                ],
                if (response.driver != null) ...[
                  DriverCardWidget(driver: response.driver!),
                  const SizedBox(height: 12),
                ],
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
