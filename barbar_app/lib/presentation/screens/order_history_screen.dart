import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/order_model.dart';
import '../bloc/marketplace/marketplace_bloc.dart';
import '../bloc/marketplace/marketplace_event.dart';
import '../bloc/marketplace/marketplace_state.dart';

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
    return Container(
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
            _detailRow('Items Total', '₹${order.itemsTotal.toInt()}'),
            _detailRow('Shipping', '₹${order.shippingCharge.toInt()}'),
            if (order.discountAmount > 0) _detailRow('Discount', '-₹${order.discountAmount.toInt()}'),
            _detailRow('Tax', '₹${order.taxAmount.toInt()}'),
            const Divider(color: AppColors.border, height: 20),
            _detailRow('Total', '₹${order.finalAmount.toInt()}', bold: true),
            const SizedBox(height: 8),
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
          ],
        ),
      ),
    );
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
      case 'processing':
        return AppColors.info;
      case 'shipped':
        return AppColors.primary;
      case 'delivered':
        return AppColors.success;
      case 'cancelled':
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
      case 'processing':
        return LucideIcons.loader;
      case 'shipped':
        return LucideIcons.truck;
      case 'delivered':
        return LucideIcons.checkCircle;
      case 'cancelled':
        return LucideIcons.xCircle;
      case 'returned':
        return LucideIcons.rotateCcw;
      default:
        return LucideIcons.helpCircle;
    }
  }
}
