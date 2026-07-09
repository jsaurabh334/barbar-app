import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/theme/app_theme.dart';

/// Wrapper around the map implementation.
/// Currently uses flutter_map (OpenStreetMap).
/// To switch to Google Maps in future:
/// 1. Replace imports with google_maps_flutter
/// 2. Replace FlutterMap/MapController with GoogleMap/GoogleMapController
/// 3. Replace Marker/MarkerLayer with Google Maps markers
class MapWidget extends StatelessWidget {
  final MapController controller;
  final LatLng initialCenter;
  final double initialZoom;
  final List<MapMarker> markers;
  final void Function(int index)? onMarkerTap;

  const MapWidget({
    super.key,
    required this.controller,
    required this.initialCenter,
    this.initialZoom = 14,
    this.markers = const [],
    this.onMarkerTap,
  });

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: controller,
      options: MapOptions(
        initialCenter: initialCenter,
        initialZoom: initialZoom,
        onTap: (_, __) {},
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://a.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}@2x.png',
          userAgentPackageName: 'com.barbar.app',
        ),
        MarkerLayer(
          markers: markers.asMap().entries.map((entry) {
            final i = entry.key;
            final m = entry.value;
            return Marker(
              point: m.point,
              width: 40,
              height: 40,
              child: GestureDetector(
                onTap: () => onMarkerTap?.call(i),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.store, color: Colors.black, size: 20),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class MapMarker {
  final double latitude;
  final double longitude;
  final String id;

  const MapMarker({
    required this.latitude,
    required this.longitude,
    required this.id,
  });

  LatLng get point => LatLng(latitude, longitude);
}
