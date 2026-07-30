import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/order_model.dart';
import '../bloc/marketplace/marketplace_bloc.dart';
import '../bloc/marketplace/marketplace_event.dart';
import '../bloc/marketplace/marketplace_state.dart';
import 'customer/customer_order_tracking_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  @override
  void initState() {
    super.initState();
    context.read<MarketplaceBloc>().add(FetchAllOrders());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ORDER HISTORY')),
      body: BlocBuilder<MarketplaceBloc, MarketplaceState>(
        builder: (context, state) {
          if (state is MarketplaceLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (state is MarketplaceFailure) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.alertCircle, size: 48, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text(state.error, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => context.read<MarketplaceBloc>().add(FetchAllOrders()),
                    icon: const Icon(LucideIcons.refreshCw),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          if (state is OrdersLoaded) {
            final orders = state.orders;
            if (orders.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.package, size: 64, color: AppColors.textSecondary),
                    const SizedBox(height: 16),
                    Text('No orders yet', style: Theme.of(context).textTheme.bodyLarge),
                    const SizedBox(height: 8),
                    Text('Visit the Shop to place your first order', style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: orders.length,
              itemBuilder: (context, index) => _buildOrderCard(orders[index]),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    final statusColor = _statusColor(order.status);
    final statusIcon = _statusIcon(order.status);
    final btnConfig = _buttonConfig(order.status);

    void openTracking() async {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CustomerOrderTrackingScreen(orderId: order.id, order: order),
        ),
      );
      if (context.mounted) {
        context.read<MarketplaceBloc>().add(FetchAllOrders());
      }
    }

    return GestureDetector(
      onTap: openTracking,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(order.orderNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 14, color: statusColor),
                        const SizedBox(width: 4),
                        Text(order.status.toUpperCase(), style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (order.items != null && order.items!.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text('Items', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                ...order.items!.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${item.quantity}x', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                          const SizedBox(width: 8),
                          Expanded(child: Text(item.productName)),
                          Text('₹${(item.price * item.quantity).toInt()}'),
                        ],
                      ),
                    )),
                const SizedBox(height: 12),
                const Divider(color: AppColors.border, height: 1),
                const SizedBox(height: 12),
              ],
              _detailRow('Items Total', '₹${order.itemsTotal.toInt()}'),
              _detailRow('Shipping', '₹${order.shippingCharge.toInt()}'),
              if (order.discountAmount > 0) _detailRow('Discount', '-₹${order.discountAmount.toInt()}'),
              _detailRow('Tax', '₹${order.taxAmount.toInt()}'),
              const Divider(color: AppColors.border, height: 20),
              _detailRow('Total', '₹${order.finalAmount.toInt()}', bold: true),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(LucideIcons.creditCard, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        order.paymentStatus.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          color: order.paymentStatus == 'paid' || order.paymentStatus == 'completed'
                              ? AppColors.success
                              : AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                  const Row(
                    children: [
                      Text('Tap for details', style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold)),
                      SizedBox(width: 2),
                      Icon(LucideIcons.chevronRight, size: 14, color: AppColors.primary),
                    ],
                  ),
                ],
              ),
                  const SizedBox(height: 14),
                  if (order.status == 'pending' || order.status == 'accepted' || order.status == 'confirmed')
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _showCancelDialog(order),
                            icon: const Icon(LucideIcons.xCircle, size: 16),
                            label: const Text('CANCEL', style: TextStyle(fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: const BorderSide(color: AppColors.error),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  if (order.status == 'delivered')
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _showReturnDialog(order),
                          icon: const Icon(LucideIcons.rotateCcw, size: 16),
                          label: const Text('REQUEST RETURN', style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                  onPressed: openTracking,
                  icon: Icon(btnConfig.$2, size: 16),
                  label: Text(
                    btnConfig.$1,
                    style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: btnConfig.$3,
                    foregroundColor: btnConfig.$4,
                    side: btnConfig.$5,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  (String, IconData, Color, Color, BorderSide?) _buttonConfig(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return ('View Details', LucideIcons.fileText, AppColors.surface, AppColors.textPrimary, const BorderSide(color: AppColors.border));
      case 'confirmed':
      case 'accepted':
        return ('View Timeline', LucideIcons.clock, AppColors.surface, AppColors.primary, const BorderSide(color: AppColors.primary));
      case 'preparing':
      case 'packed':
        return ('View Timeline', LucideIcons.package, AppColors.surface, AppColors.primary, const BorderSide(color: AppColors.primary));
      case 'ready_for_pickup':
        return ('Track Order Status', LucideIcons.mapPin, AppColors.surface, AppColors.primary, const BorderSide(color: AppColors.primary));
      case 'driver_assigned':
      case 'driver_accepted':
      case 'picked_up':
      case 'out_for_delivery':
        return ('LIVE TRACKING', LucideIcons.navigation, AppColors.primary, Colors.black, null);
      case 'delivered':
        return ('View Summary', LucideIcons.checkCircle, AppColors.surface, AppColors.success, const BorderSide(color: AppColors.success));
      case 'cancelled':
      case 'return_requested':
      case 'returned':
        return ('View Details', LucideIcons.fileText, AppColors.surface, AppColors.textMuted, const BorderSide(color: AppColors.border));
      default:
        return ('View Details', LucideIcons.fileText, AppColors.surface, AppColors.primary, const BorderSide(color: AppColors.primary));
    }
  }

  Widget _detailRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppColors.textSecondary, fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppColors.warning;
      case 'confirmed':
      case 'accepted':
        return AppColors.info;
      case 'preparing':
      case 'packed':
      case 'ready_for_pickup':
      case 'driver_assigned':
      case 'driver_accepted':
      case 'picked_up':
      case 'out_for_delivery':
        return AppColors.primary;
      case 'delivered':
        return AppColors.success;
      case 'cancelled':
      case 'return_requested':
      case 'returned':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return LucideIcons.clock;
      case 'confirmed':
      case 'accepted':
        return LucideIcons.checkCircle;
      case 'preparing':
      case 'packed':
        return LucideIcons.package;
      case 'ready_for_pickup':
        return LucideIcons.store;
      case 'driver_assigned':
      case 'driver_accepted':
      case 'picked_up':
      case 'out_for_delivery':
        return LucideIcons.navigation;
      case 'delivered':
        return LucideIcons.checkCircle;
      case 'cancelled':
        return LucideIcons.xCircle;
      case 'return_requested':
      case 'returned':
        return LucideIcons.rotateCcw;
      default:
        return LucideIcons.helpCircle;
    }
  }

  void _showCancelDialog(OrderModel order) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: const Text('Cancel Order', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Are you sure you want to cancel this order?', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Reason for cancellation (optional)',
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(color: Colors.white),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('NO', style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<MarketplaceBloc>().add(CancelOrder(
                orderId: order.id,
                reason: reasonController.text.isNotEmpty ? reasonController.text : null,
              ));
            },
            child: const Text('YES, CANCEL', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _showReturnDialog(OrderModel order) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: const Text('Return Request', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Why do you want to return this order?', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Describe the issue...',
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL', style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              context.read<MarketplaceBloc>().add(SubmitReturnRequest(
                orderId: order.id,
                reason: reasonController.text.trim(),
              ));
            },
            child: const Text('SUBMIT', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}
