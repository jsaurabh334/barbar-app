import 'package:barbar_app/presentation/bloc/admin/admin_orders_bloc.dart';
import 'package:flutter/material.dart';
import 'package:barbar_app/core/theme/app_theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:barbar_app/data/models/delivery_partner_model.dart';

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
    switch (status.toLowerCase()) {
      case 'pending': return AppColors.warning;
      case 'accepted': return AppColors.info;
      case 'packed': return const Color(0xFF4F46E5);
      case 'ready_for_pickup': return const Color(0xFF8B5CF6);
      case 'driver_assigned': return const Color(0xFF06B6D4);
      case 'picked_up': return const Color(0xFF14B8A6);
      case 'out_for_delivery': return const Color(0xFFFF6B35);
      case 'delivered': return AppColors.success;
      case 'cancelled': return AppColors.error;
      default: return AppColors.textMuted;
    }
  }

  String _fmt(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) { return iso; }
  }

  String _customerName(Map<String, dynamic> data) {
    if (data['customer'] != null && data['customer'] is Map) {
      final m = data['customer'] as Map<String, dynamic>;
      final name = (m['full_name'] ?? m['name'] ?? m['phone']) as String?;
      if (name != null && name.trim().isNotEmpty) return name;
    }
    if (data['user'] != null && data['user'] is Map) {
      final m = data['user'] as Map<String, dynamic>;
      final name = (m['full_name'] ?? m['name'] ?? m['phone']) as String?;
      if (name != null && name.trim().isNotEmpty) return name;
    }
    final cName = (data['customer_name'] ?? data['user_name'] ?? data['name']) as String?;
    if (cName != null && cName.trim().isNotEmpty) return cName;
    return 'Customer';
  }

  Future<void> _showStatusDialog() async {
    final noteController = TextEditingController();
    final selectedStatus = ValueNotifier<String?>(null);
    final statuses = ['pending', 'accepted', 'packed', 'ready_for_pickup', 'assigned', 'shipped', 'out_for_delivery', 'delivered', 'cancelled'];

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: const Text('Update Order Status', style: TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              dropdownColor: AppColors.cardBg,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(labelText: 'Status', labelStyle: TextStyle(color: AppColors.textSecondary), border: OutlineInputBorder()),
              items: statuses.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(color: AppColors.textPrimary)))).toList(),
              onChanged: (v) => selectedStatus.value = v,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(labelText: 'Note (optional)', labelStyle: TextStyle(color: AppColors.textSecondary), border: OutlineInputBorder()),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Back', style: TextStyle(color: AppColors.textSecondary))),
          ValueListenableBuilder(
            valueListenable: selectedStatus,
            builder: (_, v, __) => ElevatedButton(
              onPressed: v == null ? null : () => Navigator.pop(ctx, v),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.black),
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
    final repo = context.read<AdminOrdersBloc>().adminRepository;
    List<DeliveryPartnerModel> partners = [];
    bool loading = true;

    final selectedUserId = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.background,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            if (loading) {
              repo.getDeliveryPartners(page: 1, limit: 50, status: 'approved').then((list) {
                if (ctx.mounted) {
                  setModalState(() {
                    partners = list;
                    loading = false;
                  });
                }
              }).catchError((_) {
                if (ctx.mounted) {
                  setModalState(() => loading = false);
                }
              });
            }

            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.local_shipping, color: AppColors.primary, size: 22),
                      const SizedBox(width: 10),
                      const Text(
                        'Select Delivery Driver',
                        style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppColors.textSecondary),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (loading)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                    )
                  else if (partners.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.person_off, color: AppColors.textMuted, size: 36),
                          SizedBox(height: 8),
                          Text('No approved delivery partners found.', style: TextStyle(color: AppColors.textSecondary)),
                        ],
                      ),
                    )
                  else
                    ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.5),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: partners.length,
                        itemBuilder: (context, idx) {
                          final p = partners[idx];
                          final name = p.user?.fullName ?? 'Delivery Partner';
                          final phone = p.user?.phone ?? '';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: AppColors.cardBg,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                                child: Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : 'D',
                                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Text(name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                              subtitle: Text(
                                '${p.vehicleType.toUpperCase()} (${p.vehicleNumber})${phone.isNotEmpty ? " • $phone" : ""}',
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                              ),
                              trailing: ElevatedButton(
                                onPressed: () => Navigator.pop(ctx, p.userId),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                ),
                                child: const Text('Assign'),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );

    if (selectedUserId != null && selectedUserId.isNotEmpty && mounted) {
      context.read<AdminOrdersBloc>().add(AssignDriver(_order['id'] as String, selectedUserId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final id = _order['id'] as String? ?? '';
    final orderNumber = _order['order_number'] as String? ?? '';
    final status = _order['status'] as String? ?? 'unknown';
    final customerName = _customerName(_order);
    final customerPhone = _order['customer']?['phone'] as String? ?? _order['shipping_address']?['phone'] as String? ?? '';
    final vendorName = _order['vendor']?['business_name'] as String? ?? '';
    final deliveryPartnerName = _order['delivery_partner']?['full_name'] as String? ?? _order['delivery_partner']?['name'] as String? ?? '';
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
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: AppColors.error));
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          title: Text('#$orderNumber', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppColors.textPrimary),
              color: AppColors.cardBg,
              onSelected: (v) {
                if (v == 'status') _showStatusDialog();
                if (v == 'assign') _showAssignDialog();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'status', child: ListTile(leading: Icon(Icons.swap_horiz, color: AppColors.primary), title: Text('Update Status', style: TextStyle(color: AppColors.textPrimary)))),
                const PopupMenuItem(value: 'assign', child: ListTile(leading: Icon(Icons.local_shipping, color: AppColors.info), title: Text('Assign Driver', style: TextStyle(color: AppColors.textPrimary)))),
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
                const SizedBox(height: 14),
                _buildSection(
                  'Customer',
                  [
                    _infoRow(Icons.person, customerName),
                    if (customerPhone.isNotEmpty) _infoRow(Icons.phone, customerPhone),
                  ],
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 14),
                _buildSection(
                  'Vendor',
                  [
                    _infoRow(Icons.store, vendorName.isNotEmpty ? vendorName : 'Store Vendor'),
                  ],
                  icon: Icons.storefront,
                ),
                if (deliveryPartnerName.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _buildSection(
                    'Delivery Partner',
                    [
                      _infoRow(Icons.local_shipping, deliveryPartnerName),
                    ],
                    icon: Icons.directions_bike,
                  ),
                ],
                const SizedBox(height: 14),
                if (items.isNotEmpty)
                  _buildSection(
                    'Items (${items.length})',
                    items.map<Widget>((item) {
                      final name = item['product_name'] as String? ?? 'Product Item';
                      final qty = (item['quantity'] as num?)?.toInt() ?? 1;
                      final unitPrice = (item['unit_price'] as num?)?.toDouble() ?? 0.0;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.shopping_bag, size: 18, color: AppColors.primary),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500, fontSize: 14)),
                                  const SizedBox(height: 2),
                                  Text('qty: $qty', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                ],
                              ),
                            ),
                            Text(
                              '₹${(unitPrice * qty).toStringAsFixed(0)}',
                              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    icon: Icons.shopping_cart_outlined,
                  ),
                const SizedBox(height: 14),
                _buildSection(
                  'Payment',
                  [
                    _infoRow(Icons.receipt, '₹${itemsTotal.toStringAsFixed(2)}', label: 'Items:'),
                    if (shippingCharge > 0) _infoRow(Icons.local_shipping, '₹${shippingCharge.toStringAsFixed(2)}', label: 'Shipping:'),
                    if (taxAmount > 0) _infoRow(Icons.receipt_long, '₹${taxAmount.toStringAsFixed(2)}', label: 'Tax:'),
                    if (discountAmount > 0) _infoRow(Icons.discount, '-₹${discountAmount.toStringAsFixed(2)}', label: 'Discount:', color: AppColors.error),
                    _infoRow(Icons.payments, '₹${finalAmount.toStringAsFixed(2)}', label: 'Total:', bold: true, color: AppColors.primary),
                    _infoRow(Icons.check_circle_outline, paymentStatus.toUpperCase(), label: 'Payment Status:'),
                    if (paymentMethod.isNotEmpty) _infoRow(Icons.credit_card, paymentMethod, label: 'Method:'),
                  ],
                  icon: Icons.account_balance_wallet_outlined,
                ),
                if (shippingAddress != null) ...[
                  const SizedBox(height: 14),
                  _buildSection(
                    'Shipping Address',
                    [
                      _infoRow(Icons.location_on, _addressStr(shippingAddress)),
                    ],
                    icon: Icons.location_on_outlined,
                  ),
                ],
                if (cancellationReason != null && cancellationReason.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _buildSection(
                    'Cancellation',
                    [
                      _infoRow(Icons.info_outline, cancellationReason, color: AppColors.error),
                    ],
                    icon: Icons.cancel_outlined,
                  ),
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
    final sColor = _statusColor(status);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: sColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: sColor.withOpacity(0.4)),
            ),
            child: Text(
              status.replaceAll('_', ' ').toUpperCase(),
              style: TextStyle(fontWeight: FontWeight.bold, color: sColor, fontSize: 13, letterSpacing: 0.5),
            ),
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('#$orderNumber', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 15)),
              Text('#${id.length > 8 ? id.substring(0, 8) : id}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontFamily: 'monospace')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children, {IconData? icon}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
              ],
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, {Color? color, bool bold = false, String? label}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color ?? AppColors.textSecondary),
          const SizedBox(width: 10),
          if (label != null) ...[
            Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color ?? AppColors.textPrimary,
                fontWeight: bold ? FontWeight.bold : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _addressStr(Map<String, dynamic> addr) {
    final parts = [
      addr['line_1'] ?? addr['address_line1'],
      addr['line_2'] ?? addr['address_line2'],
      addr['city'],
      addr['state'],
      addr['pincode'],
    ];
    return parts.where((p) => p != null && p.toString().isNotEmpty).join(', ');
  }

  Widget _buildTimeline() {
    if (_timeline.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        padding: const EdgeInsets.all(16),
        child: const Center(
          child: Text('Timeline not available', style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.history, size: 18, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Timeline', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 14),
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
                    if (!isLast) Container(width: 2, height: 36, color: AppColors.border),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$from → $to', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary)),
                        if (note.isNotEmpty) Text('Note: $note', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        Text('By: $role', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                        Text(_fmt(createdAt), style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}
