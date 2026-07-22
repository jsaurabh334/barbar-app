import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/order_model.dart';
import '../../bloc/delivery/delivery_bloc.dart';
import '../../bloc/delivery/delivery_event.dart';
import '../../bloc/delivery/delivery_state.dart';
import 'delivery_order_detail_screen.dart';

class DeliveryOfferScreen extends StatefulWidget {
  final String orderId;

  const DeliveryOfferScreen({super.key, required this.orderId});

  @override
  State<DeliveryOfferScreen> createState() => _DeliveryOfferScreenState();
}

class _DeliveryOfferScreenState extends State<DeliveryOfferScreen> {
  @override
  void initState() {
    super.initState();
    context.read<DeliveryBloc>().add(FetchOrderDetail(widget.orderId));
  }

  void _claimOrder() {
    context.read<DeliveryBloc>().add(ClaimDeliveryOrder(widget.orderId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('New Delivery Available'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: BlocConsumer<DeliveryBloc, DeliveryState>(
        listener: (context, state) {
          if (state is DeliverySuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.green),
            );
          } else if (state is DeliveryFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error), backgroundColor: Colors.red),
            );
            if (state.error.toLowerCase().contains("already been taken")) {
              Navigator.pop(context);
            }
          } else if (state is DeliveryOrderDetailLoaded) {
             if (state.order.deliveryPartnerId != null) {
                 // Nav away to the actual order detail page if claimed by us
                 Navigator.pushReplacement(
                   context,
                   MaterialPageRoute(
                     builder: (_) => DeliveryOrderDetailScreen(orderId: widget.orderId),
                   ),
                 );
             }
          }
        },
        builder: (context, state) {
          if (state is DeliveryLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          
          OrderModel? order;
          if (state is DeliveryOrderDetailLoaded) {
            order = state.order;
          }
          
          if (order == null) {
            return const Center(child: Text("Loading order details..."));
          }
          
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildOfferCard(order),
                          const SizedBox(height: 24),
                          _buildDetailsCard(order),
                        ],
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _claimOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      'ACCEPT DELIVERY',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('REJECT', style: TextStyle(color: Colors.red, fontSize: 16)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOfferCard(OrderModel order) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Estimated Earnings',
                  style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
                ),
                Text(
                  '₹${order.shippingCharge}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn(LucideIcons.package, 'Items', '${order.items?.length ?? 0}'),
                _buildStatColumn(LucideIcons.banknote, 'Total', '₹${order.finalAmount}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildDetailsCard(OrderModel order) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Delivery Route',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            _buildRouteStep(
              icon: LucideIcons.store,
              title: 'Pickup from Vendor',
              address: 'Vendor #${order.orderNumber}',
              isLast: false,
            ),
            _buildRouteStep(
              icon: LucideIcons.mapPin,
              title: 'Deliver to Customer',
              address: order.customerName ?? 'Unknown Customer',
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteStep({
    required IconData icon,
    required String title,
    required String address,
    required bool isLast,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: AppColors.primary.withOpacity(0.3),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(
                  address,
                  style: const TextStyle(color: AppColors.textSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (!isLast) const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
