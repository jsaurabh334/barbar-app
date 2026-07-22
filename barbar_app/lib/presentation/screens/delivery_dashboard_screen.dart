import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/order_model.dart';
import '../../domain/repositories/delivery_repository.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_event.dart';
import '../bloc/delivery/delivery_bloc.dart';
import '../bloc/delivery/delivery_event.dart';
import '../bloc/delivery/delivery_state.dart';
import '../widgets/glass_card.dart';
import 'delivery/delivery_earnings_screen.dart';
import 'delivery/delivery_bank_screen.dart';
import 'delivery/delivery_otp_screen.dart';

class DeliveryDashboardScreen extends StatefulWidget {
  const DeliveryDashboardScreen({super.key});

  @override
  State<DeliveryDashboardScreen> createState() => _DeliveryDashboardScreenState();
}

class _DeliveryDashboardScreenState extends State<DeliveryDashboardScreen> {
  int _selectedTab = 0;
  OrderModel? _selectedOrder;
  String _presenceStatus = 'offline';
  bool _presenceLoading = false;
  Timer? _heartbeatTimer;
  Timer? _gpsTimer;
  List<OrderModel> _orders = [];

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

  static const LatLng _defaultLoc = LatLng(12.9725, 77.5955);

  @override
  void initState() {
    super.initState();
    context.read<DeliveryBloc>().add(FetchAssignedOrders());
    _loadPresence();
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    _stopGpsTracking();
    super.dispose();
  }

  Future<void> _loadPresence() async {
    try {
      final presence = await context.read<DeliveryRepository>().getMyPresence();
      if (mounted) {
        final status = (presence['status'] as String? ?? 'offline');
        setState(() => _presenceStatus = status);
        if (status == 'online' || status == 'busy') _startHeartbeat();
      }
    } catch (_) {}
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      context.read<DeliveryBloc>().add(SendHeartbeat());
    });
  }

  Future<void> _toggleOnline(bool online) async {
    setState(() => _presenceLoading = true);
    try {
      if (online) {
        context.read<DeliveryBloc>().add(GoOnline());
      } else {
        context.read<DeliveryBloc>().add(GoOffline());
        _heartbeatTimer?.cancel();
        _gpsTimer?.cancel();
      }
    } catch (_) {}
    setState(() => _presenceLoading = false);
  }

  bool get _isOnline => _presenceStatus == 'online' || _presenceStatus == 'busy';

  bool get _hasActiveDelivery => _orders.any((o) =>
    o.status == OrderModel.driverAccepted ||
    o.status == OrderModel.pickedUp ||
    o.status == OrderModel.outForDelivery);

  void _startGpsTracking() {
    _gpsTimer?.cancel();
    _gpsTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      if (!_isOnline || !_hasActiveDelivery) {
        _stopGpsTracking();
        return;
      }
      try {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10,
          ),
        );
        if (mounted) {
          context.read<DeliveryBloc>().add(UpdateDeliveryLocation(
            latitude: position.latitude,
            longitude: position.longitude,
            speed: position.speed,
            bearing: position.heading,
          ));
        }
      } catch (_) {}
    });
  }

  void _stopGpsTracking() {
    _gpsTimer?.cancel();
    _gpsTimer = null;
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
                activeTrackColor: Colors.greenAccent,
                onChanged: _presenceLoading ? null : _toggleOnline,
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
            _selectedOrder = null;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(LucideIcons.navigation), label: 'Tasks'),
          BottomNavigationBarItem(icon: Icon(LucideIcons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(LucideIcons.user), label: 'Profile'),
        ],
      ),
      body: BlocListener<DeliveryBloc, DeliveryState>(
        listener: (context, state) {
          if (state is DeliveryPresenceUpdated) {
            setState(() {
              _presenceStatus = state.status;
              if (state.status == 'online' || state.status == 'busy') {
                _startHeartbeat();
                if (_hasActiveDelivery) _startGpsTracking();
              } else {
                _heartbeatTimer?.cancel();
                _stopGpsTracking();
              }
            });
          }
          if (state is DeliveryOrdersLoaded) {
            _orders = state.orders;
            if (_isOnline && _hasActiveDelivery) {
              _startGpsTracking();
            } else {
              _stopGpsTracking();
            }
          }
        },
        child: IndexedStack(
          index: _selectedTab,
          children: [
            _buildTasksTab(),
            _buildHistoryTab(),
            _buildProfileTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildTasksTab() {
    return BlocBuilder<DeliveryBloc, DeliveryState>(
      buildWhen: (previous, current) => 
          current is DeliveryLoading || 
          current is DeliveryOrdersLoaded || 
          current is DeliveryFailure,
      builder: (context, state) {
        if (state is DeliveryLoading && state is! DeliveryOrdersLoaded) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        final orders = state is DeliveryOrdersLoaded ? state.orders : <OrderModel>[];
        final activeOrders = orders.where((o) =>
          o.status != 'delivered' && o.status != 'cancelled').toList();

        if (!_isOnline) {
          return const Center(
            child: Text(
              'Go ONLINE to receive delivery assignments.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          );
        }

        if (activeOrders.isEmpty) {
          return const Center(
            child: Text(
              'No pending delivery tasks assigned.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          );
        }

        if (_selectedOrder != null) {
          final currentOrder = activeOrders.firstWhere(
            (o) => o.id == _selectedOrder!.id,
            orElse: () => _selectedOrder!,
          );
          return _buildRouteTrackingView(currentOrder);
        }

        return RefreshIndicator(
          onRefresh: () async {
            context.read<DeliveryBloc>().add(FetchAssignedOrders());
          },
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildCurrentDeliveryCard(activeOrders),
              const SizedBox(height: 16),
              ...activeOrders.map((o) => _buildOrderCard(o, onTap: () {
                setState(() => _selectedOrder = o);
              })),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCurrentDeliveryCard(List<OrderModel> orders) {
    final active = orders.where((o) =>
      o.status == OrderModel.driverAccepted ||
      o.status == OrderModel.pickedUp ||
      o.status == OrderModel.outForDelivery).toList();

    if (active.isEmpty) return const SizedBox.shrink();

    final order = active.first;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.2),
            AppColors.cardBg,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() => _selectedOrder = order),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(LucideIcons.navigation, size: 16, color: AppColors.primary),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'CURRENT DELIVERY',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      letterSpacing: 1.5,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                order.orderNumber,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(LucideIcons.store, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
              Text(
                    'Pickup Location',
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(width: 12),
                  const Icon(LucideIcons.arrowRight, size: 14, color: AppColors.primary),
                  const SizedBox(width: 6),
                  const Icon(LucideIcons.home, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    order.customerName ?? 'Customer',
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor(order.status).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  order.status.toUpperCase().replaceAll('_', ' '),
                  style: TextStyle(
                    color: _statusColor(order.status),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
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
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    return BlocBuilder<DeliveryBloc, DeliveryState>(
      buildWhen: (previous, current) => 
          current is DeliveryLoading || 
          current is DeliveryOrdersLoaded || 
          current is DeliveryFailure,
      builder: (context, state) {
        if (state is DeliveryLoading && state is! DeliveryOrdersLoaded) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        final history = state is DeliveryOrdersLoaded
            ? state.orders.where((o) =>
                o.status == 'delivered' || o.status == 'cancelled').toList()
            : <OrderModel>[];

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
          itemBuilder: (context, index) => _buildOrderCard(history[index]),
        );
      },
    );
  }

  Widget _buildProfileTab() {
    return BlocBuilder<DeliveryBloc, DeliveryState>(
      buildWhen: (previous, current) => current is DeliveryProfileLoaded,
      builder: (context, state) {
        String name = 'Delivery Agent';
        String partnerId = '';
        int trips = 0;
        double earnings = 0;

        if (state is DeliveryProfileLoaded) {
          final p = state.profile;
          name = p.user?.fullName ?? 'Delivery Agent';
          partnerId = p.id.length > 8 ? p.id.substring(0, 8) : p.id;
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Center(
                child: Stack(
                  children: [
                    const CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.cardBg,
                      child: Icon(LucideIcons.user, size: 50, color: AppColors.primary),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.greenAccent,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, size: 14, color: Colors.black),
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  name,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
              if (partnerId.isNotEmpty) ...[
                const SizedBox(height: 4),
                Center(
                  child: Text(
                    'partner-id: $partnerId',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ),
              ],
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
                      child: Column(
                        children: [
                          const Text('Trip Earnings', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          const SizedBox(height: 6),
                          Text(
                            '₹${earnings.toInt()}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.primary),
                          ),
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
                      child: Column(
                        children: [
                          const Text('Completed Trips', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          const SizedBox(height: 6),
                          Text(
                            '$trips',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.primary),
                          ),
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
      },
    );
  }

  Widget _buildOrderCard(OrderModel o, {VoidCallback? onTap}) {
    Color color = _statusColor(o.status);

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
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      o.status.toUpperCase().replaceAll('_', ' '),
                      style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
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
                        'Pickup Location',
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
              if (o.shippingAddress != null && o.shippingAddress!['line1'] != null) ...[
                const SizedBox(height: 12),
                const Text(
                  'Delivery Location',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                ),
                const SizedBox(height: 2),
                Text(
                  '${o.shippingAddress!['line1']}${o.shippingAddress!['city'] != null ? ', ${o.shippingAddress!['city']}' : ''}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.normal),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (o.status == OrderModel.driverAssigned) ...[
                const SizedBox(height: 12),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 38,
                        child: ElevatedButton.icon(
                          onPressed: () => context.read<DeliveryBloc>().add(AcceptAssignment(o.id)),
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
                          onPressed: () => context.read<DeliveryBloc>().add(RejectAssignment(o.id)),
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
                  ],
                ),
              ],
              if (onTap != null && o.status != OrderModel.driverAssigned) ...[
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: AppColors.cardBg,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(LucideIcons.arrowLeft),
                onPressed: () => setState(() => _selectedOrder = null),
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
        Expanded(
          child: Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: o.vendorLatitude != null
                      ? LatLng(o.vendorLatitude!, o.vendorLongitude!)
                      : _defaultLoc,
                  zoom: 13.5,
                ),
                style: _darkMapStyle,
                onMapCreated: (controller) {},
                markers: {
                  if (o.vendorLatitude != null)
                    Marker(
                      markerId: const MarkerId('vendor'),
                      position: LatLng(o.vendorLatitude!, o.vendorLongitude!),
                      infoWindow: const InfoWindow(title: 'Pickup Location'),
                      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
                    ),
                  if (o.customerLatitude != null)
                    Marker(
                      markerId: const MarkerId('customer'),
                      position: LatLng(o.customerLatitude!, o.customerLongitude!),
                      infoWindow: const InfoWindow(title: 'Delivery Address (Drop)'),
                      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
                    ),
                },
                polylines: o.vendorLatitude != null && o.customerLatitude != null
                    ? {
                        Polyline(
                          polylineId: const PolylineId('route'),
                          color: AppColors.primary,
                          width: 5,
                          points: [
                            LatLng(o.vendorLatitude!, o.vendorLongitude!),
                            LatLng(o.customerLatitude!, o.customerLongitude!),
                          ],
                        ),
                      }
                    : {},
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
              ),
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
                              'Pickup: Pickup Location',
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
                              'Dropoff: ${_formatAddress(o.shippingAddress)}',
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
    switch (o.status) {
      case OrderModel.driverAssigned:
        return Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => context.read<DeliveryBloc>().add(AcceptAssignment(o.id)),
                icon: const Icon(LucideIcons.checkCircle, size: 16),
                label: const Text('ACCEPT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => context.read<DeliveryBloc>().add(RejectAssignment(o.id)),
                icon: const Icon(LucideIcons.xCircle, size: 16),
                label: const Text('REJECT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        );
      case OrderModel.driverAccepted:
      case OrderModel.assigned:
        return ElevatedButton.icon(
          onPressed: () => context.read<DeliveryBloc>().add(PickupOrder(o.id)),
          icon: const Icon(LucideIcons.package, size: 18),
          label: const Text('PICKUP ORDER', style: TextStyle(fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF14B8A6),
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      case OrderModel.pickedUp:
        return ElevatedButton.icon(
          onPressed: () => context.read<DeliveryBloc>().add(OutForDelivery(o.id)),
          icon: const Icon(LucideIcons.navigation, size: 18),
          label: const Text('OUT FOR DELIVERY', style: TextStyle(fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF6B35),
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      case OrderModel.outForDelivery:
        return ElevatedButton.icon(
          onPressed: () => _showOtpVerification(context, o),
          icon: const Icon(LucideIcons.checkCircle, size: 18),
          label: const Text('CONFIRM DELIVERY', style: TextStyle(fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.success,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  void _showOtpVerification(BuildContext context, OrderModel order) {
    final bloc = context.read<DeliveryBloc>();
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
      }
    });
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'delivered':
        return Colors.greenAccent;
      case 'cancelled':
        return AppColors.error;
      case 'out_for_delivery':
        return Colors.orangeAccent;
      case 'picked_up':
        return const Color(0xFF14B8A6);
      case 'driver_accepted':
        return Colors.teal;
      case 'driver_assigned':
        return Colors.cyan;
      default:
        return AppColors.primary;
    }
  }

  String _formatAddress(Map<String, dynamic>? addr) {
    if (addr == null) return 'Dropoff Location';
    final parts = <String>[
      if (addr['line1'] != null) addr['line1'] as String,
      if (addr['city'] != null) addr['city'] as String,
      if (addr['state'] != null) addr['state'] as String,
    ];
    return parts.isNotEmpty ? parts.join(', ') : 'Dropoff Location';
  }
}
