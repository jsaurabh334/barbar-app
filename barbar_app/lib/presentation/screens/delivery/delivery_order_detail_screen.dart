import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/order_model.dart';
import '../../../domain/repositories/delivery_repository.dart';
import '../../bloc/delivery/delivery_bloc.dart';
import '../../bloc/delivery/delivery_event.dart';
import '../../bloc/delivery/delivery_state.dart';
import 'delivery_otp_screen.dart';

class DeliveryOrderDetailScreen extends StatefulWidget {
  final String orderId;

  const DeliveryOrderDetailScreen({super.key, required this.orderId});

  @override
  State<DeliveryOrderDetailScreen> createState() => _DeliveryOrderDetailScreenState();
}

class _DeliveryOrderDetailScreenState extends State<DeliveryOrderDetailScreen> {
  OrderModel? _order;
  bool _actionLoading = false;
  double? _etaMinutes;
  double? _distanceKm;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    context.read<DeliveryBloc>().add(FetchOrderDetail(widget.orderId));
    _loadEta();
  }

  Future<void> _loadEta() async {
    try {
      final eta = await context.read<DeliveryRepository>().getOrderETA(widget.orderId);
      if (mounted) {
        setState(() {
          _etaMinutes = (eta['eta_minutes'] as num?)?.toDouble();
          _distanceKm = (eta['distance_km'] as num?)?.toDouble();
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Delivery Order')),
      body: BlocBuilder<DeliveryBloc, DeliveryState>(
        builder: (context, state) {
          if (state is DeliveryLoading && _order == null && !_actionLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          if (state is DeliveryFailure && _order == null) {
            return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(LucideIcons.alertCircle, size: 48, color: AppColors.textSecondary),
              const SizedBox(height: 16),
              Text(state.error, style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _load, child: const Text('Retry')),
            ]));
          }

          if (state is DeliveryOrderDetailLoaded) {
            _order = state.order;
          }

          if (_order == null) {
            return const SizedBox.shrink();
          }

          return _buildContent(_order!);
        },
      ),
    );
  }

  Widget _buildContent(OrderModel order) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildOrderInfoCard(order),
          const SizedBox(height: 16),
          if (order.items != null && order.items!.isNotEmpty)
            _buildItemsCard(order.items!),
          const SizedBox(height: 16),
          if (order.customerName != null)
            _buildCustomerCard(order),
          const SizedBox(height: 16),
          _buildNavigationCard(order),
          const SizedBox(height: 16),
          if (_etaMinutes != null || _distanceKm != null)
            _buildEtaCard(),
          if (_etaMinutes != null || _distanceKm != null)
            const SizedBox(height: 16),
          if (order.statusLog != null && order.statusLog!.isNotEmpty)
            _buildTimelineCard(order.statusLog!),
          const SizedBox(height: 16),
          _buildActionButtons(order),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildOrderInfoCard(OrderModel order) {
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
          Row(children: [
            Text('#${order.orderNumber}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const Spacer(),
            _statusBadge(order.status),
          ]),
          const SizedBox(height: 12),
          _infoRow(LucideIcons.indianRupee, 'Total', '₹${order.finalAmount.toStringAsFixed(2)}'),
          const SizedBox(height: 6),
          _infoRow(LucideIcons.creditCard, 'Payment', order.paymentStatus.toUpperCase()),
        ],
      ),
    );
  }

  Widget _buildItemsCard(List items) {
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
          const Row(children: [
            Icon(LucideIcons.package, size: 18, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Items', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ]),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              Expanded(child: Text(item.productName, style: const TextStyle(fontWeight: FontWeight.w600))),
              Text('x${item.quantity}', style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(width: 12),
              Text('₹${item.price.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
            ]),
          )),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(OrderModel order) {
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
          const Row(children: [
            Icon(LucideIcons.user, size: 18, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Customer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ]),
          const SizedBox(height: 12),
          _infoRow(LucideIcons.user, 'Name', order.customerName ?? 'N/A'),
          if (order.customerPhone != null) ...[
            const SizedBox(height: 6),
            _infoRow(LucideIcons.phone, 'Phone', order.customerPhone!),
          ],
          if (order.shippingAddress != null) ...[
            const SizedBox(height: 6),
            _infoRow(LucideIcons.mapPin, 'Address', _formatAddress(order.shippingAddress!)),
          ],
        ],
      ),
    );
  }

  Widget _buildTimelineCard(List<Map<String, dynamic>> statusLog) {
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
          const Row(children: [
            Icon(LucideIcons.clock, size: 18, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Timeline', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ]),
          const SizedBox(height: 16),
          ...List.generate(statusLog.length, (index) {
            final entry = statusLog[index];
            final isLast = index == statusLog.length - 1;
            return _timelineItem(
              entry['status'] as String? ?? '',
              entry['timestamp'] as String? ?? '',
              entry['note'] as String?,
              isLast: isLast,
            );
          }),
        ],
      ),
    );
  }

  Widget _timelineItem(String status, String timestamp, String? note, {bool isLast = false}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Column(children: [
              Container(width: 12, height: 12, decoration: BoxDecoration(color: _statusColor(status), shape: BoxShape.circle)),
              if (!isLast) Expanded(child: Container(width: 2, color: AppColors.border)),
            ]),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(status.toUpperCase().replaceAll('_', ' '),
                      style: TextStyle(fontWeight: FontWeight.w600, color: _statusColor(status))),
                  Text(_formatDateStr(timestamp), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  if (note != null && note.isNotEmpty)
                    Text(note, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationCard(OrderModel order) {
    final hasPickup = order.vendorLatitude != null && order.vendorLongitude != null;
    final hasDrop = order.customerLatitude != null && order.customerLongitude != null;

    if (!hasPickup && !hasDrop) return const SizedBox.shrink();

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
          const Row(children: [
            Icon(LucideIcons.navigation, size: 18, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Navigation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ]),
          const SizedBox(height: 12),
          if (hasPickup)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _launchGoogleMaps(order.vendorLatitude!, order.vendorLongitude!),
                icon: const Icon(LucideIcons.mapPin, size: 16),
                label: const Text('Navigate to Pickup'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          if (hasPickup && hasDrop) const SizedBox(height: 8),
          if (hasDrop)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _launchGoogleMaps(order.customerLatitude!, order.customerLongitude!),
                icon: const Icon(LucideIcons.home, size: 16),
                label: const Text('Navigate to Customer'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _launchGoogleMaps(double lat, double lng) async {
    final uri = Uri.parse('google.navigation:q=$lat,$lng');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      final webUri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
      if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not launch maps'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  Widget _buildActionButtons(OrderModel order) {
    if (_actionLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    final bloc = context.read<DeliveryBloc>();

    switch (order.status) {
      case OrderModel.driverAssigned:
        return Row(children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                bloc.add(AcceptAssignment(order.id));
                setState(() => _actionLoading = true);
              },
              icon: const Icon(LucideIcons.checkCircle, size: 18),
              label: const Text('ACCEPT', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                bloc.add(RejectAssignment(order.id));
                setState(() => _actionLoading = true);
              },
              icon: const Icon(LucideIcons.xCircle, size: 18),
              label: const Text('REJECT', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ]);
      case OrderModel.driverAccepted:
      case OrderModel.assigned:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              bloc.add(PickupOrder(order.id));
              setState(() => _actionLoading = true);
            },
            icon: const Icon(LucideIcons.package, size: 18),
            label: const Text('PICKUP ORDER', style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF14B8A6),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        );
      case OrderModel.pickedUp:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              bloc.add(OutForDelivery(order.id));
              setState(() => _actionLoading = true);
            },
            icon: const Icon(LucideIcons.navigation, size: 18),
            label: const Text('OUT FOR DELIVERY', style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B35),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        );
      case OrderModel.outForDelivery:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DeliveryOtpScreen(
                    orderId: order.id,
                    title: 'Delivery OTP',
                    subtitle: 'Ask the customer for the OTP to confirm delivery',
                    otpType: 'delivery',
                  ),
                ),
              ).then((verified) {
                if (verified == true) {
                  bloc.add(DeliverOrder(order.id));
                  setState(() => _actionLoading = true);
                }
              });
            },
            icon: const Icon(LucideIcons.checkCircle, size: 18),
            label: const Text('CONFIRM DELIVERY', style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        );
      case OrderModel.delivered:
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
          ),
          child: const Row(
            children: [
              Icon(LucideIcons.checkCircle, color: AppColors.success, size: 20),
              SizedBox(width: 12),
              Text('Order Delivered', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildEtaCard() {
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
          const Row(children: [
            Icon(LucideIcons.clock, size: 18, color: AppColors.warning),
            SizedBox(width: 8),
            Text('ETA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            const Icon(LucideIcons.navigation, size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            const Text('Distance: ', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            Text(
              _distanceKm != null ? '${_distanceKm!.toStringAsFixed(1)} km' : '--',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const Spacer(),
            const Icon(LucideIcons.clock, size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            const Text('ETA: ', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            Text(
              _etaMinutes != null ? '${_etaMinutes!.toStringAsFixed(0)} min' : '--',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(children: [
      Icon(icon, size: 14, color: AppColors.textSecondary),
      const SizedBox(width: 8),
      Text('$label: ', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
    ]);
  }

  Widget _statusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: _statusColor(status).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
      child: Text(status.toUpperCase().replaceAll('_', ' '),
          style: TextStyle(color: _statusColor(status), fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'driver_assigned': return Colors.cyan;
      case 'driver_accepted': return Colors.teal;
      case 'assigned': return const Color(0xFF06B6D4);
      case 'picked_up': return const Color(0xFF14B8A6);
      case 'out_for_delivery': return const Color(0xFFFF6B35);
      case 'delivered': return AppColors.success;
      default: return AppColors.textSecondary;
    }
  }

  String _formatDateStr(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatAddress(Map<String, dynamic> addr) {
    final parts = <String>[
      if (addr['line1'] != null) addr['line1'] as String,
      if (addr['line2'] != null) addr['line2'] as String,
      if (addr['city'] != null) addr['city'] as String,
      if (addr['state'] != null) addr['state'] as String,
      if (addr['pincode'] != null) addr['pincode'] as String,
    ];
    return parts.join(', ');
  }
}
