import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/order_model.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_event.dart';
import '../bloc/marketplace/marketplace_bloc.dart';
import '../bloc/marketplace/marketplace_event.dart';
import '../bloc/marketplace/marketplace_state.dart';
import '../widgets/glass_card.dart';
import 'delivery/delivery_earnings_screen.dart';
import 'delivery/delivery_bank_screen.dart';

class DeliveryDashboardScreen extends StatefulWidget {
  const DeliveryDashboardScreen({super.key});

  @override
  State<DeliveryDashboardScreen> createState() => _DeliveryDashboardScreenState();
}

class _DeliveryDashboardScreenState extends State<DeliveryDashboardScreen> {
  int _selectedTab = 0;
  bool _isOnline = true;
  OrderModel? _selectedOrder;

  static const String _darkMapStyle = '''
  [
    {
      "elementType": "geometry",
      "stylers": [{"color": "#12121a"}]
    },
    {
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#8e8e93"}]
    },
    {
      "elementType": "labels.text.stroke",
      "stylers": [{"color": "#12121a"}]
    },
    {
      "featureType": "road",
      "elementType": "geometry",
      "stylers": [{"color": "#1b1b25"}]
    },
    {
      "featureType": "water",
      "elementType": "geometry",
      "stylers": [{"color": "#09090c"}]
    }
  ]
  ''';

  // Fixed coordinates for simulated route
  static const LatLng _defaultLoc = LatLng(12.9725, 77.5955);

  @override
  void initState() {
    super.initState();
    context.read<MarketplaceBloc>().add(FetchAllOrders());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'DELIVERY CONSOLE',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2),
        ),
        actions: [
          Row(
            children: [
              Text(
                _isOnline ? 'ONLINE' : 'OFFLINE',
                style: TextStyle(
                  color: _isOnline ? Colors.greenAccent : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Switch(
                value: _isOnline,
                activeColor: Colors.greenAccent,
                onChanged: (val) {
                  setState(() {
                    _isOnline = val;
                  });
                },
              ),
            ],
          ),
          IconButton(
            icon: const Icon(LucideIcons.logOut),
            onPressed: () => context.read<AuthBloc>().add(LogoutRequested()),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTab,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        backgroundColor: AppColors.surface,
        onTap: (index) {
          setState(() {
            _selectedTab = index;
            _selectedOrder = null; // Reset selection on tab switch
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(LucideIcons.navigation), label: 'Tasks'),
          BottomNavigationBarItem(icon: Icon(LucideIcons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(LucideIcons.user), label: 'Profile'),
        ],
      ),
      body: IndexedStack(
        index: _selectedTab,
        children: [
          _buildTasksTab(),
          _buildHistoryTab(),
          _buildProfileTab(),
        ],
      ),
    );
  }

  Widget _buildTasksTab() {
    return BlocBuilder<MarketplaceBloc, MarketplaceState>(
      builder: (context, state) {
        if (state is MarketplaceLoading) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        } else if (state is OrdersLoaded) {
          // Filter tasks (exclude delivered and cancelled)
          final tasks = state.orders
              .where((o) => o.status != 'delivered' && o.status != 'cancelled')
              .toList();

          if (!_isOnline) {
            return const Center(
              child: Text(
                'Go ONLINE to receive delivery assignments.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }

          if (tasks.isEmpty) {
            return const Center(
              child: Text(
                'No pending delivery tasks assigned.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }

          if (_selectedOrder != null) {
            // Check if selected order is still valid or updated
            final currentOrder = tasks.firstWhere(
              (o) => o.id == _selectedOrder!.id,
              orElse: () => _selectedOrder!,
            );
            return _buildRouteTrackingView(currentOrder);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final o = tasks[index];
              return _buildOrderCard(o, onTap: () {
                setState(() {
                  _selectedOrder = o;
                });
              });
            },
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildHistoryTab() {
    return BlocBuilder<MarketplaceBloc, MarketplaceState>(
      builder: (context, state) {
        if (state is MarketplaceLoading) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        } else if (state is OrdersLoaded) {
          final history = state.orders
              .where((o) => o.status == 'delivered' || o.status == 'cancelled')
              .toList();

          if (history.isEmpty) {
            return const Center(
              child: Text(
                'No completed deliveries found.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: history.length,
            itemBuilder: (context, index) {
              return _buildOrderCard(history[index]);
            },
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          const Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.cardBg,
                  child: Icon(LucideIcons.user, size: 50, color: AppColors.primary),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.greenAccent,
                    child: Icon(Icons.check, size: 16, color: Colors.black),
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'Demo Delivery Agent',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
          const Center(
            child: Text(
              'partner-id: DEL-8947',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Column(
                    children: [
                      Text('Trip Earnings', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      SizedBox(height: 6),
                      Text('₹4,850', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.primary)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Column(
                    children: [
                      Text('Completed Trips', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      SizedBox(height: 6),
                      Text('24', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.primary)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(LucideIcons.wallet, color: AppColors.primary),
                  title: const Text('Earnings'),
                  trailing: const Icon(LucideIcons.chevronRight, size: 18),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DeliveryEarningsScreen()),
                  ),
                ),
                const Divider(height: 1, color: AppColors.border),
                ListTile(
                  leading: const Icon(LucideIcons.building2, color: AppColors.primary),
                  title: const Text('Bank Account'),
                  trailing: const Icon(LucideIcons.chevronRight, size: 18),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DeliveryBankScreen()),
                  ),
                ),
                const Divider(height: 1, color: AppColors.border),
                ListTile(
                  leading: const Icon(LucideIcons.shieldAlert, color: AppColors.primary),
                  title: const Text('License & Vehicle Verification'),
                  trailing: const Text(
                    'VERIFIED',
                    style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  onTap: () {},
                ),
                const Divider(height: 1, color: AppColors.border),
                ListTile(
                  leading: const Icon(LucideIcons.navigation2, color: AppColors.primary),
                  title: const Text('GPS Calibration'),
                  trailing: const Icon(LucideIcons.chevronRight, size: 18),
                  onTap: () {},
                ),
                const Divider(height: 1, color: AppColors.border),
                ListTile(
                  leading: const Icon(LucideIcons.headphones, color: AppColors.primary),
                  title: const Text('Support Hotline'),
                  trailing: const Icon(LucideIcons.chevronRight, size: 18),
                  onTap: () {},
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildOrderCard(OrderModel o, {VoidCallback? onTap}) {
    Color statusColor;
    switch (o.status) {
      case 'delivered':
        statusColor = Colors.greenAccent;
        break;
      case 'cancelled':
        statusColor = AppColors.error;
        break;
      case 'out_for_delivery':
        statusColor = Colors.orangeAccent;
        break;
      case 'shipped':
        statusColor = Colors.lightBlueAccent;
        break;
      default:
        statusColor = AppColors.primary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    o.orderNumber,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      o.status.toUpperCase().replaceAll('_', ' '),
                      style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pickup Point',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Style Products Hub',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white.withValues(alpha: 0.9)),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Customer Pay',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '₹${o.finalAmount.toInt()}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Delivery Location',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
              ),
              const SizedBox(height: 2),
              const Text(
                '102, Brigade Road, MG Road, Bangalore',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.normal),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (onTap != null) ...[
                const SizedBox(height: 12),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 12),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tap to open routing map',
                      style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold),
                    ),
                    Icon(LucideIcons.arrowRight, size: 16, color: AppColors.primary),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRouteTrackingView(OrderModel o) {
    return Column(
      children: [
        // App bar like header inside tab
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: AppColors.cardBg,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(LucideIcons.arrowLeft),
                onPressed: () {
                  setState(() {
                    _selectedOrder = null;
                  });
                },
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      o.orderNumber,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      'Transit Route Tracking',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),

        // Route map
        Expanded(
          child: Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _selectedOrder?.vendorLatitude != null
                      ? LatLng(_selectedOrder!.vendorLatitude!, _selectedOrder!.vendorLongitude!)
                      : _defaultLoc,
                  zoom: 13.5,
                ),
                style: _darkMapStyle,
                onMapCreated: (controller) {},
                markers: {
                  if (_selectedOrder?.vendorLatitude != null)
                    Marker(
                      markerId: const MarkerId('vendor'),
                      position: LatLng(_selectedOrder!.vendorLatitude!, _selectedOrder!.vendorLongitude!),
                      infoWindow: const InfoWindow(title: 'Pickup Location'),
                      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
                    ),
                  if (_selectedOrder?.customerLatitude != null)
                    Marker(
                      markerId: const MarkerId('customer'),
                      position: LatLng(_selectedOrder!.customerLatitude!, _selectedOrder!.customerLongitude!),
                      infoWindow: const InfoWindow(title: 'Delivery Address (Drop)'),
                      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
                    ),
                },
                polylines: _selectedOrder?.vendorLatitude != null && _selectedOrder?.customerLatitude != null
                    ? {
                        Polyline(
                          polylineId: const PolylineId('route'),
                          color: AppColors.primary,
                          width: 5,
                          points: [
                            LatLng(_selectedOrder!.vendorLatitude!, _selectedOrder!.vendorLongitude!),
                            LatLng(_selectedOrder!.customerLatitude!, _selectedOrder!.customerLongitude!),
                          ],
                        ),
                      }
                    : {},
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
              ),

              // floating Overlay detailing details and action
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: GlassCard(
                  padding: const EdgeInsets.all(16),
                  opacity: 0.15,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'ROUTE DETAIL',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.5),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              o.status.toUpperCase(),
                              style: const TextStyle(color: AppColors.primary, fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(LucideIcons.store, color: AppColors.primary, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Pickup: Style Products Hub, Brigade Road',
                              style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.9)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(LucideIcons.home, color: AppColors.primary, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Dropoff: 102, Brigade Road, Bangalore',
                              style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.9)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildActionButton(context, o),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context, OrderModel o) {
    String buttonText = '';
    String nextStatus = '';

    if (o.status == 'confirmed' || o.status == 'processing' || o.status == 'pending') {
      buttonText = 'START PACKAGE PICKUP';
      nextStatus = 'shipped';
    } else if (o.status == 'shipped') {
      buttonText = 'MARK OUT FOR DELIVERY';
      nextStatus = 'out_for_delivery';
    } else if (o.status == 'out_for_delivery') {
      buttonText = 'CONFIRM PACKAGE HANDOVER';
      nextStatus = 'delivered';
    } else {
      return const SizedBox.shrink();
    }

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      onPressed: () {
        context.read<MarketplaceBloc>().add(
              UpdateOrderStatus(orderId: o.id, status: nextStatus),
            );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order Status updated to $nextStatus'),
            backgroundColor: AppColors.primary,
          ),
        );
        // Automatically close mapping view if order status is delivered
        if (nextStatus == 'delivered') {
          setState(() {
            _selectedOrder = null;
          });
        } else {
          setState(() {
            _selectedOrder = OrderModel(
              id: o.id,
              orderNumber: o.orderNumber,
              status: nextStatus,
              itemsTotal: o.itemsTotal,
              shippingCharge: o.shippingCharge,
              taxAmount: o.taxAmount,
              discountAmount: o.discountAmount,
              finalAmount: o.finalAmount,
              paymentStatus: o.paymentStatus,
            );
          });
        }
      },
      child: Text(
        buttonText,
        style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
      ),
    );
  }
}
