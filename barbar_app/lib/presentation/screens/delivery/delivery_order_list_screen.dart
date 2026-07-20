import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/order_model.dart';
import '../../../domain/repositories/delivery_repository.dart';
import 'delivery_order_detail_screen.dart';

class DeliveryOrderListScreen extends StatefulWidget {
  const DeliveryOrderListScreen({super.key});

  @override
  State<DeliveryOrderListScreen> createState() => _DeliveryOrderListScreenState();
}

class _DeliveryOrderListScreenState extends State<DeliveryOrderListScreen> {
  List<OrderModel>? _orders;
  bool _loading = true;
  String? _error;

  bool _isOnline = false;
  String _presenceStatus = 'offline';
  Timer? _heartbeatTimer;
  Timer? _gpsTimer;

  bool get _hasActiveDelivery {
    if (_orders == null) return false;
    return _orders!.any((o) =>
      o.status == OrderModel.driverAccepted ||
      o.status == OrderModel.pickedUp ||
      o.status == OrderModel.outForDelivery,
    );
  }

  @override
  void initState() {
    super.initState();
    _loadOrders();
    _loadPresence();
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    _gpsTimer?.cancel();
    super.dispose();
  }

  void _startGpsTimer() {
    _gpsTimer?.cancel();
    _gpsTimer = Timer.periodic(const Duration(seconds: 8), (_) async {
      if (!_isOnline || !_hasActiveDelivery) {
        _stopGpsTimer();
        return;
      }
      final lat = 21.1938 + (Random().nextDouble() - 0.5) * 0.01;
      final lng = 81.3509 + (Random().nextDouble() - 0.5) * 0.01;
      try {
        await context.read<DeliveryRepository>().sendLocation(
          latitude: lat,
          longitude: lng,
          speed: 10 + Random().nextDouble() * 20,
          bearing: Random().nextDouble() * 360,
          timestamp: DateTime.now().toUtc().toIso8601String(),
        );
      } catch (_) {}
    });
  }

  void _stopGpsTimer() {
    _gpsTimer?.cancel();
    _gpsTimer = null;
  }

  Future<void> _loadPresence() async {
    try {
      final presence = await context.read<DeliveryRepository>().getMyPresence();
      if (mounted) {
        final status = (presence['status'] as String? ?? 'offline');
        setState(() {
          _presenceStatus = status;
          _isOnline = status == 'online' || status == 'busy';
        });
        if (_isOnline) _startHeartbeat();
      }
    } catch (_) {}
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      try {
        await context.read<DeliveryRepository>().heartbeat();
      } catch (_) {}
    });
  }

  Future<void> _toggleOnline(bool online) async {
    try {
      if (online) {
        final result = await context.read<DeliveryRepository>().goOnline();
        if (mounted) {
          setState(() {
            _isOnline = true;
            _presenceStatus = result['status'] as String? ?? 'online';
          });
          _startHeartbeat();
        }
      } else {
        await context.read<DeliveryRepository>().goOffline();
        _heartbeatTimer?.cancel();
        _stopGpsTimer();
        if (mounted) {
          setState(() {
            _isOnline = false;
            _presenceStatus = 'offline';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _loadOrders() async {
    setState(() { _loading = true; _error = null; });
    try {
      final orders = await context.read<DeliveryRepository>().getAssignedOrders();
      if (mounted) {
        setState(() { _orders = orders; _loading = false; });
        if (_isOnline && _hasActiveDelivery) _startGpsTimer();
        else _stopGpsTimer();
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString().replaceAll('Exception: ', ''); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Delivery Orders')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_error != null) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(LucideIcons.alertCircle, size: 48, color: AppColors.textSecondary),
        const SizedBox(height: 16),
        Text(_error!, style: const TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: _loadOrders, child: const Text('Retry')),
      ]));
    }
    if (_orders == null || _orders!.isEmpty) {
      return ListView(children: [
        _buildPresenceToggle(),
        const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(height: 40),
          Icon(LucideIcons.truck, size: 64, color: AppColors.textSecondary),
          SizedBox(height: 16),
          Text('No assigned orders', style: TextStyle(color: AppColors.textSecondary)),
        ])),
      ]);
    }
    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildPresenceToggle(),
          const SizedBox(height: 12),
          ..._orders!.map((o) => _buildOrderCard(o)),
        ],
      ),
    );
  }

  Widget _buildPresenceToggle() {
    Color statusColor;
    String statusText;
    switch (_presenceStatus) {
      case 'online':
        statusColor = AppColors.success;
        statusText = 'You are Online';
        break;
      case 'busy':
        statusColor = AppColors.warning;
        statusText = 'You are Busy';
        break;
      default:
        statusColor = AppColors.error;
        statusText = 'You are Offline';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: statusColor.withValues(alpha: 0.5), blurRadius: 6),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              statusText,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          Switch(
            value: _isOnline,
            activeColor: AppColors.success,
            onChanged: _toggleOnline,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DeliveryOrderDetailScreen(orderId: order.id)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text('#${order.orderNumber}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const Spacer(),
                _statusChip(order.status),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                const Icon(LucideIcons.indianRupee, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text('₹${order.finalAmount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
                const Spacer(),
                Text(order.paymentStatus, style: TextStyle(fontSize: 12, color: order.paymentStatus == 'paid' ? AppColors.success : AppColors.warning)),
              ]),
              if (order.status == OrderModel.driverAssigned) ...[
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: SizedBox(
                      height: 38,
                      child: ElevatedButton.icon(
                        onPressed: () => _handleAcceptAssignment(order.id),
                        icon: const Icon(LucideIcons.checkCircle, size: 16),
                        label: const Text('Accept', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 38,
                      child: ElevatedButton.icon(
                        onPressed: () => _handleRejectAssignment(order.id),
                        icon: const Icon(LucideIcons.xCircle, size: 16),
                        label: const Text('Reject', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ),
                ]),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleAcceptAssignment(String orderId) async {
    try {
      await context.read<DeliveryRepository>().acceptAssignment(orderId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Assignment accepted'), backgroundColor: AppColors.success),
        );
        _loadOrders();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _handleRejectAssignment(String orderId) async {
    try {
      await context.read<DeliveryRepository>().rejectAssignment(orderId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Assignment rejected'), backgroundColor: AppColors.success),
        );
        _loadOrders();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Widget _statusChip(String status) {
    Color color;
    switch (status) {
      case 'driver_assigned': color = Colors.cyan; break;
      case 'driver_accepted': color = Colors.teal; break;
      case 'assigned': color = const Color(0xFF06B6D4); break;
      case 'picked_up': color = const Color(0xFF14B8A6); break;
      case 'out_for_delivery': color = const Color(0xFFFF6B35); break;
      case 'delivered': color = AppColors.success; break;
      default: color = AppColors.textSecondary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
      child: Text(status.toUpperCase().replaceAll('_', ' '), style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold)),
    );
  }
}
