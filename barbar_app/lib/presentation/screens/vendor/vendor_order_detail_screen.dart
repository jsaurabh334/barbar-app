import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/order_model.dart';
import '../../bloc/vendor/vendor_bloc.dart';
import '../../bloc/vendor/vendor_event.dart';
import '../../bloc/vendor/vendor_state.dart';
import 'vendor_order_tracking_screen.dart';

class VendorOrderDetailScreen extends StatefulWidget {
  final String orderId;

  const VendorOrderDetailScreen({super.key, required this.orderId});

  @override
  State<VendorOrderDetailScreen> createState() => _VendorOrderDetailScreenState();
}

class _VendorOrderDetailScreenState extends State<VendorOrderDetailScreen> {
  @override
  void initState() {
    super.initState();
    context.read<VendorBloc>().add(LoadVendorOrderDetail(widget.orderId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order Detail')),
      body: BlocListener<VendorBloc, VendorState>(
        listener: (context, state) {
          if (state is VendorSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColors.success),
            );
          }
          if (state is VendorFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error), backgroundColor: AppColors.error),
            );
          }
        },
        child: BlocBuilder<VendorBloc, VendorState>(
          builder: (context, state) {
            if (state is VendorLoading && state is! VendorOrderDetailLoaded) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primary));
            }
            if (state is VendorOrderDetailLoaded) {
              return _buildContent(state.order);
            }
            if (state is VendorFailure) {
              return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(LucideIcons.alertCircle, size: 48, color: AppColors.textSecondary),
                const SizedBox(height: 16),
                Text(state.error, style: const TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.read<VendorBloc>().add(LoadVendorOrderDetail(widget.orderId)),
                  child: const Text('Retry'),
                ),
              ]));
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildContent(OrderModel order) {
    final isDeliveryActive = order.status == OrderModel.driverAssigned ||
        order.status == OrderModel.driverAccepted ||
        order.status == OrderModel.assigned ||
        order.status == OrderModel.pickedUp ||
        order.status == OrderModel.outForDelivery;

    final hasDeliveryPartner = order.deliveryPartner != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildOrderInfoCard(order),
          const SizedBox(height: 16),
          if (order.items != null && order.items!.isNotEmpty) ...[
            _buildItemsCard(order.items!),
            const SizedBox(height: 16),
          ],
          if (hasDeliveryPartner) ...[
            _buildDeliveryPartnerCard(order),
            const SizedBox(height: 16),
          ],
          if (isDeliveryActive) ...[
            _buildTrackDeliveryButton(order),
            const SizedBox(height: 16),
          ],
          if (order.customerName != null) ...[
            _buildCustomerInfoCard(order),
            const SizedBox(height: 16),
          ],
          if (_hasDeliveryEvents(order)) ...[
            _buildDeliveryHistory(order),
            const SizedBox(height: 16),
          ],
          if (order.statusLog != null && order.statusLog!.isNotEmpty) ...[
            _buildTimelineCard(order.statusLog!),
            const SizedBox(height: 16),
          ],
          _buildActionButtons(order),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildDeliveryPartnerCard(OrderModel order) {
    final dp = order.deliveryPartner!;
    final name = dp['name'] as String? ?? 'Delivery Partner';
    final phone = dp['phone'] as String? ?? '';
    final avatar = dp['avatar'] as String?;
    final vehicleType = dp['vehicle_type'] as String?;
    final vehicleNumber = dp['vehicle_number'] as String?;
    final rating = dp['rating'];

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
              Icon(LucideIcons.truck, size: 18, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Delivery Partner', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                child: avatar == null
                    ? const Icon(LucideIcons.user, color: AppColors.primary, size: 24)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    if (phone.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(phone, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    ],
                    if (vehicleType != null || vehicleNumber != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${vehicleType ?? ''}${vehicleType != null && vehicleNumber != null ? ' · ' : ''}${vehicleNumber ?? ''}',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
              if (rating != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.star, size: 14, color: AppColors.warning),
                      const SizedBox(width: 4),
                      Text(
                        rating is num ? rating.toStringAsFixed(1) : 'N/A',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (phone.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final uri = Uri.parse('tel:$phone');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  }
                },
                icon: const Icon(LucideIcons.phone, size: 16),
                label: const Text('Call Driver'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTrackDeliveryButton(OrderModel order) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VendorOrderTrackingScreen(orderId: order.id),
          ),
        ),
        icon: const Icon(LucideIcons.navigation, size: 18),
        label: const Text('Track Delivery', style: TextStyle(fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  bool _hasDeliveryEvents(OrderModel order) {
    if (order.statusLog == null) return false;
    final deliveryStatuses = {
      OrderModel.driverAssigned, OrderModel.driverAccepted,
      OrderModel.assigned, OrderModel.pickedUp,
      OrderModel.outForDelivery, OrderModel.delivered,
    };
    return order.statusLog!.any((e) => deliveryStatuses.contains(e['status'] as String?));
  }

  Widget _buildDeliveryHistory(OrderModel order) {
    final deliveryStatuses = {
      OrderModel.driverAssigned, OrderModel.driverAccepted,
      OrderModel.assigned, OrderModel.pickedUp,
      OrderModel.outForDelivery, OrderModel.delivered,
    };
    final labels = {
      OrderModel.driverAssigned: 'Driver Assigned',
      OrderModel.driverAccepted: 'Driver Accepted',
      OrderModel.assigned: 'Out for Pickup',
      OrderModel.pickedUp: 'Picked Up',
      OrderModel.outForDelivery: 'Out for Delivery',
      OrderModel.delivered: 'Delivered',
    };
    final icons = {
      OrderModel.driverAssigned: LucideIcons.userCheck,
      OrderModel.driverAccepted: LucideIcons.checkCircle,
      OrderModel.assigned: LucideIcons.navigation,
      OrderModel.pickedUp: LucideIcons.package,
      OrderModel.outForDelivery: LucideIcons.mapPin,
      OrderModel.delivered: LucideIcons.checkCircle,
    };
    final entries = order.statusLog!
        .where((e) => deliveryStatuses.contains(e['status'] as String?))
        .toList()
      ..sort((a, b) {
        final at = DateTime.tryParse(a['timestamp'] as String? ?? '');
        final bt = DateTime.tryParse(b['timestamp'] as String? ?? '');
        if (at == null || bt == null) return 0;
        return at.compareTo(bt);
      });

    if (entries.isEmpty) return const SizedBox.shrink();

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
              Icon(LucideIcons.truck, size: 18, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Delivery History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 16),
          ...entries.map((entry) {
            final status = entry['status'] as String? ?? '';
            final ts = entry['timestamp'] as String? ?? '';
            final date = ts.isNotEmpty ? _formatDateStr(ts) : '';
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(icons[status] ?? LucideIcons.clock, size: 16, color: _statusColor(status)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      labels[status] ?? status.replaceAll('_', ' '),
                      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                    ),
                  ),
                  if (date.isNotEmpty)
                    Text(date, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            );
          }),
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
          Row(
            children: [
              const Icon(LucideIcons.shoppingBag, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('#${order.orderNumber}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const Spacer(),
              _statusBadge(order.status),
            ],
          ),
          const SizedBox(height: 12),
          if (order.createdAt != null) ...[
            _infoRow(LucideIcons.calendar, 'Placed', _formatDate(order.createdAt!)),
            const SizedBox(height: 6),
          ],
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
          const Row(
            children: [
              Icon(LucideIcons.package, size: 18, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Items', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.productName, style: const TextStyle(fontWeight: FontWeight.w600)),
                      if (item.variantName != null)
                        Text(item.variantName, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                Text('x${item.quantity}', style: const TextStyle(color: AppColors.textSecondary)),
                const SizedBox(width: 12),
                Text('₹${item.price.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildCustomerInfoCard(OrderModel order) {
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
              Icon(LucideIcons.user, size: 18, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Customer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 12),
          _infoRow(LucideIcons.user, 'Name', order.customerName ?? 'N/A'),
          const SizedBox(height: 6),
          if (order.customerPhone != null) ...[
            _infoRow(LucideIcons.phone, 'Phone', order.customerPhone!),
            const SizedBox(height: 6),
          ],
          if (order.shippingAddress != null) ...[
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
          const Row(
            children: [
              Icon(LucideIcons.clock, size: 18, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Timeline', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 16),
          ...List.generate(statusLog.length, (index) {
            final entry = statusLog[index];
            final isLast = index == statusLog.length - 1;
            final status = entry['status'] as String? ?? '';
            final timestamp = entry['timestamp'] as String? ?? '';
            final note = entry['note'] as String?;
            return _timelineItem(status, timestamp, note, isLast: isLast);
          }),
        ],
      ),
    );
  }

  Widget _timelineItem(String status, String timestamp, String? note, {bool isLast = false}) {
    final date = timestamp.isNotEmpty ? _formatDateStr(timestamp) : '';
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _statusColor(status),
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(width: 2, color: AppColors.border),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    status.toUpperCase().replaceAll('_', ' '),
                    style: TextStyle(fontWeight: FontWeight.w600, color: _statusColor(status)),
                  ),
                  if (date.isNotEmpty)
                    Text(date, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
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

  Widget _buildActionButtons(OrderModel order) {
    final actions = _getActionsForStatus(order.status);

    if (actions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        for (final action in actions) ...[
          if (action.type == 'info')
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: action.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: action.color.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(action.icon, color: action.color, size: 20),
                  const SizedBox(width: 12),
                  Text(action.label, style: TextStyle(color: action.color, fontWeight: FontWeight.bold)),
                ],
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _handleAction(action, order.id),
                icon: Icon(action.icon, size: 18),
                label: Text(action.label, style: const TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: action.color,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          if (action != actions.last) const SizedBox(height: 12),
        ],
      ],
    );
  }

  List<_ActionButton> _getActionsForStatus(String status) {
    switch (status) {
      case OrderModel.pending:
        return [
          _ActionButton('Accept Order', LucideIcons.checkCircle, AppColors.success, 'action'),
          _ActionButton('Reject Order', LucideIcons.xCircle, AppColors.error, 'action'),
        ];
      case OrderModel.accepted:
        return [
          _ActionButton('Pack Order', LucideIcons.package, AppColors.info, 'action'),
        ];
      case OrderModel.packed:
        return [
          _ActionButton('Ready for Pickup', LucideIcons.truck, const Color(0xFF8B5CF6), 'action'),
        ];
      case OrderModel.readyForPickup:
        return [
          _ActionButton('Waiting for delivery partner', LucideIcons.clock, AppColors.textSecondary, 'info'),
        ];
      case OrderModel.driverAssigned:
        return [
          _ActionButton('Driver Assigned', LucideIcons.userCheck, Colors.cyan, 'info'),
        ];
      case OrderModel.driverAccepted:
        return [
          _ActionButton('Driver Accepted', LucideIcons.userCheck, Colors.teal, 'info'),
        ];
      case OrderModel.assigned:
        return [
          _ActionButton('Out for pickup', LucideIcons.navigation, const Color(0xFF06B6D4), 'info'),
        ];
      case OrderModel.pickedUp:
        return [
          _ActionButton('In transit', LucideIcons.truck, const Color(0xFF14B8A6), 'info'),
        ];
      case OrderModel.outForDelivery:
        return [
          _ActionButton('Out for delivery', LucideIcons.mapPin, const Color(0xFFFF6B35), 'info'),
        ];
      case OrderModel.delivered:
        return [
          _ActionButton('Delivered', LucideIcons.checkCircle, AppColors.success, 'info'),
        ];
      case OrderModel.cancelled:
        return [
          _ActionButton('Cancelled', LucideIcons.xCircle, AppColors.error, 'info'),
        ];
      default:
        return [];
    }
  }

  void _handleAction(_ActionButton action, String orderId) {
    final bloc = context.read<VendorBloc>();
    switch (action.label) {
      case 'Accept Order':
        bloc.add(AcceptVendorOrder(orderId));
        break;
      case 'Reject Order':
        _showRejectDialog(orderId);
        break;
      case 'Pack Order':
        bloc.add(PackVendorOrder(orderId));
        break;
      case 'Ready for Pickup':
        bloc.add(ReadyForPickupOrder(orderId));
        break;
    }
  }

  void _showRejectDialog(String orderId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Reject Order'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Reason for rejection',
            hintText: 'Enter reason...',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (controller.text.trim().isNotEmpty) {
                context.read<VendorBloc>().add(RejectVendorOrder(orderId, controller.text.trim()));
              }
            },
            child: const Text('REJECT'),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        Expanded(
          child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ),
      ],
    );
  }

  Widget _statusBadge(String status) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase().replaceAll('_', ' '),
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case OrderModel.pending:
        return AppColors.warning;
      case OrderModel.accepted:
        return AppColors.info;
      case OrderModel.packed:
        return const Color(0xFF4F46E5);
      case OrderModel.readyForPickup:
        return const Color(0xFF8B5CF6);
      case OrderModel.driverAssigned:
        return Colors.cyan;
      case OrderModel.driverAccepted:
        return Colors.teal;
      case OrderModel.assigned:
        return const Color(0xFF06B6D4);
      case OrderModel.pickedUp:
        return const Color(0xFF14B8A6);
      case OrderModel.outForDelivery:
        return const Color(0xFFFF6B35);
      case OrderModel.delivered:
        return AppColors.success;
      case OrderModel.cancelled:
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatDateStr(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    return _formatDate(dt);
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

class _ActionButton {
  final String label;
  final IconData icon;
  final Color color;
  final String type;

  _ActionButton(this.label, this.icon, this.color, this.type);
}
