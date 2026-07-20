import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/tracking/tracking_response.dart';

class TrackingMapWidget extends StatefulWidget {
  final TrackingResponse response;
  final DriverInfo? previousDriver;

  const TrackingMapWidget({
    super.key,
    required this.response,
    this.previousDriver,
  });

  @override
  State<TrackingMapWidget> createState() => _TrackingMapWidgetState();
}

class _TrackingMapWidgetState extends State<TrackingMapWidget>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  late AnimationController _animController;
  LatLng? _animatedDriverPos;
  bool _autoFollow = true;
  bool _hasInitialFit = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void didUpdateWidget(TrackingMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _animateDriverMarker();
    _autoFollowDriver();
  }

  void _animateDriverMarker() {
    final driver = widget.response.driver;
    if (driver?.latitude == null || driver?.longitude == null) return;

    final newPos = LatLng(driver!.latitude!, driver.longitude!);

    if (_animatedDriverPos == null) {
      _animatedDriverPos = newPos;
      return;
    }

    final dist = const Distance().distance(_animatedDriverPos!, newPos);
    if (dist.isNaN || dist < 1) return;

    final start = _animatedDriverPos!;
    final end = newPos;

    _animController.reset();
    _animController.addListener(() {
      final t = _animController.value;
      final lat = start.latitude + (end.latitude - start.latitude) * t;
      final lng = start.longitude + (end.longitude - start.longitude) * t;
      setState(() {
        _animatedDriverPos = LatLng(lat, lng);
      });
    });
    _animController.forward();
  }

  void _autoFollowDriver() {
    if (!_autoFollow) return;
    final driver = widget.response.driver;
    if (driver?.latitude == null || driver?.longitude == null) return;

    _mapController.move(
      LatLng(driver!.latitude!, driver.longitude!),
      15.0,
    );
  }

  void _fitInitialBounds() {
    if (_hasInitialFit) return;
    _hasInitialFit = true;

    final latLngs = <LatLng>[];
    final driver = widget.response.driver;
    final warehouse = widget.response.warehouse;
    final customer = widget.response.customer;

    if (driver?.latitude != null && driver?.longitude != null) {
      latLngs.add(LatLng(driver!.latitude!, driver.longitude!));
    }
    if (warehouse != null && warehouse.latitude != 0 && warehouse.longitude != 0) {
      latLngs.add(LatLng(warehouse.latitude, warehouse.longitude));
    }
    if (customer != null && customer.latitude != 0 && customer.longitude != 0) {
      latLngs.add(LatLng(customer.latitude, customer.longitude));
    }

    if (latLngs.isEmpty) return;
    if (latLngs.length == 1) {
      _mapController.move(latLngs.first, 14.0);
      return;
    }

    final bounds = LatLngBounds.fromPoints(latLngs);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(60),
      ),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _fitInitialBounds());

    final warehouse = widget.response.warehouse;
    final customer = widget.response.customer;

    final markers = <Marker>[];

    if (warehouse != null && warehouse.latitude != 0 && warehouse.longitude != 0) {
      markers.add(_buildMarker(
        LatLng(warehouse.latitude, warehouse.longitude),
        LucideIcons.warehouse,
        AppColors.warning,
        'Pickup: ${warehouse.name}',
      ));
    }

    if (customer != null && customer.latitude != 0 && customer.longitude != 0) {
      markers.add(_buildMarker(
        LatLng(customer.latitude, customer.longitude),
        LucideIcons.home,
        AppColors.success,
        'Delivery: ${customer.fullAddress.length > 30 ? '${customer.fullAddress.substring(0, 30)}...' : customer.fullAddress}',
      ));
    }

    final driverPos = _animatedDriverPos;
    if (driverPos != null) {
      markers.add(Marker(
        point: driverPos,
        width: 40,
        height: 40,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.4),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(Icons.delivery_dining, color: Colors.black, size: 20),
        ),
      ));
    }

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: driverPos ?? const LatLng(21.1938, 81.3509),
              initialZoom: 14.0,
              onMapEvent: (event) {
                if (event is MapEventMoveStart) {
                  setState(() => _autoFollow = false);
                }
              },
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.barbar.app',
              ),
              MarkerLayer(markers: markers),
              if (driverPos != null && customer != null &&
                  customer.latitude != 0 && customer.longitude != 0)
                PolylineLayer(polylines: [
                  Polyline(
                    points: [driverPos, LatLng(customer.latitude, customer.longitude)],
                    color: AppColors.primary.withValues(alpha: 0.6),
                    strokeWidth: 3,
                  ),
                ]),
            ],
          ),
        ),
        if (!_autoFollow)
          Positioned(
            right: 12,
            bottom: 12,
            child: FloatingActionButton.small(
              heroTag: 'center_driver',
              backgroundColor: AppColors.cardBg,
              onPressed: () {
                setState(() => _autoFollow = true);
                _autoFollowDriver();
              },
              child: const Icon(LucideIcons.navigation, color: AppColors.primary, size: 20),
            ),
          ),
      ],
    );
  }

  Marker _buildMarker(LatLng point, IconData icon, Color color, String label) {
    return Marker(
      point: point,
      width: 80,
      height: 80,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 9),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Icon(icon, color: Colors.white, size: 16),
          ),
        ],
      ),
    );
  }
}
