import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/services/location_service.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/barber_model.dart';
import '../bloc/directory/directory_bloc.dart';
import '../bloc/directory/directory_event.dart';
import '../bloc/directory/directory_state.dart';
import '../widgets/map_widget.dart';
import 'barber_detail_screen.dart';
import '../widgets/glass_card.dart';

class MapDiscoveryScreen extends StatefulWidget {
  const MapDiscoveryScreen({super.key});

  @override
  State<MapDiscoveryScreen> createState() => _MapDiscoveryScreenState();
}

class _MapDiscoveryScreenState extends State<MapDiscoveryScreen> {
  final _locationService = LocationService();
  final _searchController = TextEditingController();
  final _mapController = MapController();
  LatLng _userPosition = const LatLng(LocationService.defaultLatitude, LocationService.defaultLongitude);
  List<BarberModel> _salons = [];
  PageController? _pageController;
  double? _selectedMinRating;
  bool _openNow = false;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85);
    _getUserLocation();
  }

  @override
  void dispose() {
    _pageController?.dispose();
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _getUserLocation() async {
    final result = await _locationService.getCoordinates();
    if (!mounted) return;
    setState(() {
      _userPosition = LatLng(result.latitude, result.longitude);
      _locationError = result.error != null ? _locationErrorMessage(result.error!) : null;
    });
    _fetchBarbers();
  }

  String _locationErrorMessage(LocationError error) {
    switch (error) {
      case LocationError.denied:
        return 'Location permission denied. Showing all nearby shops.';
      case LocationError.deniedForever:
        return 'Location permission permanently denied. Enable in Settings to see shops near you.';
      case LocationError.gpsDisabled:
        return 'GPS is disabled. Turn on location for accurate results.';
      case LocationError.timeout:
        return 'Location timed out. Showing all nearby shops.';
      case LocationError.unknown:
        return 'Unable to get your location. Showing all nearby shops.';
    }
  }

  void _fetchBarbers({String? categoryId}) {
    final state = context.read<DirectoryBloc>().state;
    String? finalCategoryId = categoryId;
    if (finalCategoryId == null && state is DirectoryLoaded) {
      finalCategoryId = state.selectedCategory?.id;
    }

    context.read<DirectoryBloc>().add(
      FetchNearbyBarbers(
        latitude: _userPosition.latitude,
        longitude: _userPosition.longitude,
        search: _searchController.text.isNotEmpty ? _searchController.text : null,
        minRating: _selectedMinRating,
        openNow: _openNow ? true : null,
        categoryId: finalCategoryId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map
          BlocConsumer<DirectoryBloc, DirectoryState>(
            listener: (context, state) {
              if (state is DirectoryLoaded) {
                setState(() => _salons = state.barbers);
              }
            },
            builder: (context, state) {
              return MapWidget(
                controller: _mapController,
                initialCenter: _userPosition,
                markers: _salons
                    .map((s) => MapMarker(latitude: s.latitude, longitude: s.longitude, id: s.id))
                    .toList(),
                onMarkerTap: (index) {
                  _pageController?.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
              );
            },
          ),

          // Overlay UI
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top bar
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.surface,
                        child: IconButton(
                          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (_) => _fetchBarbers(),
                          decoration: InputDecoration(
                            hintText: 'Search salons...',
                            prefixIcon: const Icon(LucideIcons.search, size: 20),
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            filled: true,
                            fillColor: AppColors.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Filters
                  Row(
                    children: [
                      _buildFilterChip('3+', _selectedMinRating == 3.0, () {
                        setState(() => _selectedMinRating = _selectedMinRating == 3.0 ? null : 3.0);
                        _fetchBarbers();
                      }),
                      const SizedBox(width: 8),
                      _buildFilterChip('4+', _selectedMinRating == 4.0, () {
                        setState(() => _selectedMinRating = _selectedMinRating == 4.0 ? null : 4.0);
                        _fetchBarbers();
                      }),
                      const SizedBox(width: 8),
                      _buildFilterChip('5+', _selectedMinRating == 5.0, () {
                        setState(() => _selectedMinRating = _selectedMinRating == 5.0 ? null : 5.0);
                        _fetchBarbers();
                      }),
                      const SizedBox(width: 8),
                      _buildToggleChip('Open Now', _openNow, () {
                        setState(() => _openNow = !_openNow);
                        _fetchBarbers();
                      }),
                    ],
                  ),

                  // Location error banner
                  if (_locationError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.mapPin, size: 16, color: AppColors.warning),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _locationError!,
                                style: const TextStyle(color: AppColors.warning, fontSize: 12),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() => _locationError = null);
                                _getUserLocation();
                              },
                              child: const Icon(LucideIcons.refreshCw, size: 16, color: AppColors.warning),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const Spacer(),
                ],
              ),
            ),
          ),

          // Loading / Error overlay
          Positioned(
            left: 0,
            right: 0,
            bottom: 200,
            child: BlocBuilder<DirectoryBloc, DirectoryState>(
              builder: (context, s) {
                if (s is DirectoryLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }
                if (s is DirectoryFailure) {
                  return Center(
                    child: TextButton.icon(
                      onPressed: _fetchBarbers,
                      icon: const Icon(LucideIcons.refreshCw, size: 16),
                      label: const Text('Retry'),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),

          // Carousel overlay (separate from SafeArea/Column to avoid gesture conflict)
          if (_salons.isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              bottom: 12,
              height: 160,
              child: PageView.builder(
                controller: _pageController,
                scrollBehavior: const ScrollBehavior().copyWith(overscroll: false),
                itemCount: _salons.length,
                onPageChanged: (index) {
                  final salon = _salons[index];
                  _mapController.move(
                    LatLng(salon.latitude, salon.longitude),
                    14,
                  );
                },
                itemBuilder: (context, index) => _buildCarouselItem(_salons[index]),
              ),
            ),

          // Recenter button
          Positioned(
            right: 16,
            bottom: 180,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.primary,
              onPressed: () => _mapController.move(_userPosition, 14),
              child: const Icon(LucideIcons.crosshair),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star, size: 12, color: isSelected ? Colors.black : AppColors.textSecondary),
            const SizedBox(width: 3),
            Text(label,
                style: TextStyle(
                    color: isSelected ? Colors.black : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleChip(String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? AppColors.success.withValues(alpha: 0.15) : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isActive ? AppColors.success : AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.clock, size: 12, color: isActive ? AppColors.success : AppColors.textSecondary),
            const SizedBox(width: 3),
            Text(label,
                style: TextStyle(
                    color: isActive ? AppColors.success : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildCarouselItem(BarberModel barber) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (c) => BarberDetailScreen(barber: barber)),
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
                child: CachedNetworkImage(
                  imageUrl: barber.fullShopImage ?? '',
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                  errorWidget: (c, _, __) => Container(
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
                    Text(barber.shopName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(barber.address,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(LucideIcons.users, size: 14, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text('${barber.currentQueueLength} waiting',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.primary)),
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
