import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/services/location_service.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/barber_model.dart';
import '../bloc/directory/directory_bloc.dart';
import '../bloc/directory/directory_event.dart';
import '../bloc/directory/directory_state.dart';
import 'barber_detail_screen.dart';
import '../widgets/glass_card.dart';

class MapDiscoveryScreen extends StatefulWidget {
  const MapDiscoveryScreen({super.key});

  @override
  State<MapDiscoveryScreen> createState() => _MapDiscoveryScreenState();
}

class _MapDiscoveryScreenState extends State<MapDiscoveryScreen> {
  GoogleMapController? _mapController;
  final _locationService = LocationService();
  LatLng _userPosition = const LatLng(LocationService.defaultLatitude, LocationService.defaultLongitude);
  final Set<Marker> _markers = {};
  PageController? _pageController;
  List<BarberModel> _salons = [];

  // Dark Map Theme styling JSON
  static const String _darkMapStyle = '''
  [
    {
      "elementType": "geometry",
      "stylers": [
        {
          "color": "#12121a"
        }
      ]
    },
    {
      "elementType": "labels.text.fill",
      "stylers": [
        {
          "color": "#8e8e93"
        }
      ]
    },
    {
      "elementType": "labels.text.stroke",
      "stylers": [
        {
          "color": "#12121a"
        }
      ]
    },
    {
      "featureType": "administrative",
      "elementType": "geometry.stroke",
      "stylers": [
        {
          "color": "#262635"
        }
      ]
    },
    {
      "featureType": "poi",
      "elementType": "labels.text.fill",
      "stylers": [
        {
          "color": "#d4af37"
        }
      ]
    },
    {
      "featureType": "road",
      "elementType": "geometry",
      "stylers": [
        {
          "color": "#1b1b25"
        }
      ]
    },
    {
      "featureType": "road",
      "elementType": "geometry.stroke",
      "stylers": [
        {
          "color": "#262635"
        }
      ]
    },
    {
      "featureType": "water",
      "elementType": "geometry",
      "stylers": [
        {
          "color": "#09090c"
        }
      ]
    }
  ]
  ''';

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85);
    _getUserLocation();
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  Future<void> _getUserLocation() async {
    final coords = await _locationService.getCoordinates();
    final userPos = LatLng(coords['latitude']!, coords['longitude']!);
    if (mounted) {
      setState(() {
        _userPosition = userPos;
      });
      context.read<DirectoryBloc>().add(
        FetchNearbyBarbers(latitude: userPos.latitude, longitude: userPos.longitude),
      );
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _userPosition, zoom: 14),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Google Map Background
          BlocConsumer<DirectoryBloc, DirectoryState>(
            listener: (context, state) {
              if (state is DirectoryLoaded) {
                setState(() {
                  _salons = state.barbers;
                  _updateMarkers(state.barbers);
                });
              }
            },
            builder: (context, state) {
              return GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _userPosition,
                  zoom: 14,
                ),
                style: _darkMapStyle,
                onMapCreated: _onMapCreated,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                markers: _markers,
              );
            },
          ),

          // Safe Area controls
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Bar / Back
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.surface,
                        child: IconButton(
                          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'DISCOVER SALONS',
                        style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 16),
                      ),
                    ],
                  ),
                  const Spacer(),

                  // Horizontal Carousel of Salons
                  if (_salons.isNotEmpty)
                    SizedBox(
                      height: 140,
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: _salons.length,
                        onPageChanged: (index) {
                          final salon = _salons[index];
                          _mapController?.animateCamera(
                            CameraUpdate.newLatLng(LatLng(salon.latitude, salon.longitude)),
                          );
                        },
                        itemBuilder: (context, index) {
                          return _buildCarouselItem(_salons[index]);
                        },
                      ),
                    ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          // Recenter Button
          Positioned(
            right: 16,
            bottom: 180,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.primary,
              onPressed: () {
                _mapController?.animateCamera(
                  CameraUpdate.newLatLng(_userPosition),
                );
              },
              child: const Icon(LucideIcons.crosshair),
            ),
          ),
        ],
      ),
    );
  }

  void _updateMarkers(List<BarberModel> salons) {
    final Set<Marker> newMarkers = {};
    for (int i = 0; i < salons.length; i++) {
      final s = salons[i];
      newMarkers.add(
        Marker(
          markerId: MarkerId(s.id),
          position: LatLng(s.latitude, s.longitude),
          infoWindow: InfoWindow(title: s.shopName, snippet: s.address),
          onTap: () {
            _pageController?.animateToPage(
              i,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
        ),
      );
    }
    setState(() {
      _markers.clear();
      _markers.addAll(newMarkers);
    });
  }

  Widget _buildCarouselItem(BarberModel barber) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (c) => BarberDetailScreen(barber: barber),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        child: GlassCard(
          padding: const EdgeInsets.all(12),
          opacity: 0.12,
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  barber.shopImage ?? '',
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                  errorBuilder: (c, _, __) => Container(
                    width: 90,
                    height: 90,
                    color: AppColors.surface,
                    child: const Icon(LucideIcons.scissors, color: AppColors.textSecondary),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      barber.shopName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      barber.address,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(LucideIcons.users, size: 14, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          '${barber.currentQueueLength} waiting',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
