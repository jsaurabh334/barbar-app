import 'package:barbar_app/presentation/bloc/admin/admin_orders_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AdminOrderDetailScreen extends StatefulWidget {
  final Map<String, dynamic> orderData;
  const AdminOrderDetailScreen({super.key, required this.orderData});
  @override
  State<AdminOrderDetailScreen> createState() => _AdminOrderDetailScreenState();
}

class _AdminOrderDetailScreenState extends State<AdminOrderDetailScreen> {
  late Map<String, dynamic> _order;
  List<dynamic> _timeline = [];

  @override
  void initState() {
    super.initState();
    _order = widget.orderData;
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    final repo = context.read<AdminOrdersBloc>().adminRepository;
    try {
      final detail = await repo.getAdminOrderDetail(_order['id'] as String);
      if (mounted) setState(() => _order = detail);
    } catch (_) {}
    try {
      final timeline = await repo.getAdminOrderTimeline(_order['id'] as String);
      if (mounted) setState(() => _timeline = timeline);
    } catch (_) {}
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'accepted': return Colors.blue;
      case 'packed': return Colors.indigo;
      case 'ready_for_pickup': return Colors.cyan;
      case 'driver_assigned': return Colors.lightBlue;
      case 'picked_up': return Colors.lime;
      case 'out_for_delivery': return Colors.amber;
      case 'delivered': return Colors.teal;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _fmt(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) { return iso; }
  }

  Future<void> _showStatusDialog() async {
    final noteController = TextEditingController();
    final selectedStatus = ValueNotifier<String?>(null);
    final statuses = ['pending', 'accepted', 'packed', 'ready_for_pickup', 'assigned', 'shipped', 'out_for_delivery', 'delivered', 'cancelled'];

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update Order Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
              items: statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (v) => selectedStatus.value = v,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(labelText: 'Note (optional)', border: OutlineInputBorder()),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Back')),
          ValueListenableBuilder(
            valueListenable: selectedStatus,
            builder: (_, v, __) => ElevatedButton(
              onPressed: v == null ? null : () => Navigator.pop(ctx, v),
              child: const Text('Update'),
            ),
          ),
        ],
      ),
    );

    if (result != null && mounted) {
      context.read<AdminOrdersBloc>().add(UpdateOrderStatus(
        _order['id'] as String, result, note: noteController.text,
      ));
    }
  }

  Future<void> _showAssignDialog() async {
    final driverController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Assign Driver'),
        content: TextField(
          controller: driverController,
          decoration: const InputDecoration(labelText: 'Driver User ID', hintText: 'UUID of delivery partner', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Back')),
          ElevatedButton(
            onPressed: () => driverController.text.isNotEmpty ? Navigator.pop(ctx, driverController.text) : null,
            child: const Text('Assign'),
          ),
        ],
      ),
    );
    if (result != null && mounted) {
      context.read<AdminOrdersBloc>().add(AssignDriver(_order['id'] as String, result));
    }
  }

  @override
  Widget build(BuildContext context) {
    final id = _order['id'] as String? ?? '';
    final orderNumber = _order['order_number'] as String? ?? '';
    final status = _order['status'] as String? ?? 'unknown';
    final customerName = _order['customer']?['full_name'] as String? ?? 'Guest';
    final customerPhone = _order['customer']?['phone'] as String? ?? '';
    final vendorName = _order['vendor']?['business_name'] as String? ?? '';
    final deliveryPartnerName = _order['delivery_partner']?['full_name'] as String? ?? '';
    final finalAmount = (_order['final_amount'] as num?)?.toDouble() ?? 0.0;
    final itemsTotal = (_order['items_total'] as num?)?.toDouble() ?? 0.0;
    final shippingCharge = (_order['shipping_charge'] as num?)?.toDouble() ?? 0.0;
    final taxAmount = (_order['tax_amount'] as num?)?.toDouble() ?? 0.0;
    final discountAmount = (_order['discount_amount'] as num?)?.toDouble() ?? 0.0;
    final paymentStatus = _order['payment_status'] as String? ?? '';
    final paymentMethod = _order['payment_method'] as String? ?? '';
    final cancellationReason = _order['cancellation_reason'] as String?;
    final shippingAddress = _order['shipping_address'] as Map<String, dynamic>?;
    final items = (_order['items'] as List<dynamic>?) ?? [];

    return BlocListener<AdminOrdersBloc, AdminOrdersState>(
      listener: (context, state) {
        if (state is AdminOrderActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
          context.read<AdminOrdersBloc>().add(LoadOrders(page: 1));
          Navigator.pop(context, true);
        } else if (state is AdminOrdersError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.red));
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('#$orderNumber'),
          actions: [
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'status') _showStatusDialog();
                if (v == 'assign') _showAssignDialog();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'status', child: ListTile(leading: Icon(Icons.swap_horiz), title: Text('Update Status'))),
                const PopupMenuItem(value: 'assign', child: ListTile(leading: Icon(Icons.local_shipping), title: Text('Assign Driver'))),
              ],
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _loadDetail,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(status, orderNumber, id),
                const SizedBox(height: 16),
                _buildSection('Customer', [
                  _infoRow(Icons.person, customerName),
                  if (customerPhone.isNotEmpty) _infoRow(Icons.phone, customerPhone),
                ]),
                const SizedBox(height: 12),
                _buildSection('Vendor', [
                  _infoRow(Icons.store, vendorName),
                ]),
                if (deliveryPartnerName.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildSection('Delivery Partner', [
                    _infoRow(Icons.local_shipping, deliveryPartnerName),
                  ]),
                ],
                const SizedBox(height: 12),
                if (items.isNotEmpty) _buildSection('Items ($items.length)', [
                  ...items.map((item) {
                    final name = item['product_name'] as String? ?? '';
                    final qty = (item['quantity'] as num?)?.toInt() ?? 1;
                    final unitPrice = (item['unit_price'] as num?)?.toDouble() ?? 0.0;
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.shopping_bag, size: 18),
                      title: Text(name, style: const TextStyle(fontSize: 13)),
                      subtitle: Text('qty: $qty', style: const TextStyle(fontSize: 11)),
                      trailing: Text('₹${(unitPrice * qty).toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                    );
                  }),
                ]),
                const SizedBox(height: 12),
                _buildSection('Payment', [
                  _infoRow(Icons.receipt, 'Items: ₹${itemsTotal.toStringAsFixed(2)}'),
                  if (shippingCharge > 0) _infoRow(Icons.local_shipping, 'Shipping: ₹${shippingCharge.toStringAsFixed(2)}'),
                  if (taxAmount > 0) _infoRow(Icons.receipt_long, 'Tax: ₹${taxAmount.toStringAsFixed(2)}'),
                  if (discountAmount > 0) _infoRow(Icons.discount, 'Discount: -₹${discountAmount.toStringAsFixed(2)}'),
                  _infoRow(Icons.payments, 'Total: ₹${finalAmount.toStringAsFixed(2)}', bold: true),
                  _infoRow(Icons.check_circle_outline, 'Payment: $paymentStatus'),
                  if (paymentMethod.isNotEmpty) _infoRow(Icons.credit_card, 'Method: $paymentMethod'),
                ]),
                if (shippingAddress != null) ...[
                  const SizedBox(height: 12),
                  _buildSection('Shipping Address', [
                    _infoRow(Icons.location_on, _addressStr(shippingAddress)),
                  ]),
                ],
                if (cancellationReason != null && cancellationReason.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildSection('Cancellation', [
                    _infoRow(Icons.info_outline, cancellationReason, color: Colors.red),
                  ]),
                ],
                const SizedBox(height: 16),
                _buildTimeline(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String status, String orderNumber, String id) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _statusColor(status).withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(status, style: TextStyle(fontWeight: FontWeight.bold, color: _statusColor(status), fontSize: 16)),
            ),
            const Spacer(),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('#$orderNumber', style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(id.length > 8 ? id.substring(0, 8) : id, style: TextStyle(fontSize: 11, color: Colors.grey[400])),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, {Color? color, bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color ?? Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(color: color, fontWeight: bold ? FontWeight.w600 : null, fontSize: 13))),
        ],
      ),
    );
  }

  String _addressStr(Map<String, dynamic> addr) {
    final parts = [
      addr['address_line1'], addr['address_line2'], addr['city'],
      addr['state'], addr['pincode'],
    ];
    return parts.where((p) => p != null && p.toString().isNotEmpty).join(', ');
  }

  Widget _buildTimeline() {
    if (_timeline.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: Text('Timeline not available', style: TextStyle(color: Colors.grey))),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Timeline', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const Divider(),
            ...List.generate(_timeline.length, (i) {
              final entry = _timeline[i];
              final from = entry['from_status'] as String? ?? '';
              final to = entry['to_status'] as String? ?? '';
              final role = entry['role'] as String? ?? '';
              final note = entry['note'] as String? ?? '';
              final createdAt = entry['created_at'] as String? ?? '';
              final isLast = i == _timeline.length - 1;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Icon(Icons.circle, size: 12, color: _statusColor(to)),
                      if (!isLast) Container(width: 2, height: 40, color: Colors.grey[300]),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('$from → $to', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          if (note.isNotEmpty) Text('Note: $note', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                          Text('By: $role', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                          Text(_fmt(createdAt), style: TextStyle(fontSize: 10, color: Colors.grey[400])),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}
