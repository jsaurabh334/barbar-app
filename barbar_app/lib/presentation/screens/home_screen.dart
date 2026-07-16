import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:geolocator/geolocator.dart';
import '../../data/models/barber_model.dart';
import '../../data/models/booking_model.dart';
import '../../data/models/category_model.dart';
import '../../core/network/websocket_client.dart';
import '../../core/theme/app_theme.dart';
import 'barber_detail_screen.dart';
import 'map_discovery_screen.dart';
import 'shop_screen.dart';
import 'wallet_screen.dart';
import 'queue_tracker_screen.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_event.dart';
import '../bloc/auth/auth_state.dart';
import '../bloc/booking/booking_bloc.dart';
import '../bloc/booking/booking_event.dart';
import '../bloc/booking/booking_state.dart';
import '../bloc/directory/directory_bloc.dart';
import '../bloc/directory/directory_event.dart';
import '../bloc/directory/directory_state.dart';
import '../bloc/notification/notification_bloc.dart';
import '../bloc/notification/notification_event.dart';
import '../widgets/glass_card.dart';
import '../widgets/notification_bell.dart';

class HomeScreen extends StatefulWidget {
  final WebSocketClient webSocketClient;

  const HomeScreen({
    super.key,
    required this.webSocketClient,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  bool _isLiveSynced = false;
  double? _selectedMinRating;
  bool _openNow = false;
  double _currentLat = 12.9716;
  double _currentLng = 77.5946;
  BookingModel? _activeBooking;

  @override
  void initState() {
    super.initState();

    _determinePosition();

    context.read<DirectoryBloc>().add(const FetchCategories());
    context.read<BookingBloc>().add(FetchAllBookings());

    widget.webSocketClient.connect();
    widget.webSocketClient.connectionStatus.listen((connected) {
      if (mounted) {
        setState(() {
          _isLiveSynced = connected;
        });
      }
    });

    widget.webSocketClient.events.listen((event) {
      if (!mounted) return;
      final type = event['type'] as String?;
      if (type == 'notification') {
        final payload = event['payload'] as Map<String, dynamic>?;
        if (payload != null) {
          context.read<NotificationBloc>().add(NewWebSocketNotification(payload));
        }
        return;
      }
      if (_activeBooking == null) return;
      if (type == 'queue_update') {
        final payload = event['payload'] as Map<String, dynamic>;
        final position = payload['current_position'] as int;
        final waitMin = (payload['estimated_wait_min'] as num).toDouble();

        context.read<DirectoryBloc>().add(
          UpdateBarberQueue(
            barberId: _activeBooking!.barberId,
            currentQueueLength: position + 2,
            averageWaitTime: waitMin,
          ),
        );
      }
    });
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _fetchBarbers();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _fetchBarbers();
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _fetchBarbers();
      return;
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (mounted) {
        setState(() {
          _currentLat = pos.latitude;
          _currentLng = pos.longitude;
        });
        _fetchBarbers();
      }
    } catch (e) {
      _fetchBarbers();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    widget.webSocketClient.disconnect();
    super.dispose();
  }

  void _fetchBarbers({String? categoryId}) {
    final state = context.read<DirectoryBloc>().state;
    String? finalCategoryId = categoryId;
    if (finalCategoryId == null && state is DirectoryLoaded) {
      finalCategoryId = state.selectedCategory?.id;
    }

    context.read<DirectoryBloc>().add(
      FetchNearbyBarbers(
        latitude: _currentLat,
        longitude: _currentLng,
        search: _searchController.text.isNotEmpty ? _searchController.text : null,
        minRating: _selectedMinRating,
        openNow: _openNow ? true : null,
        categoryId: finalCategoryId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    String userName = 'Guest';
    String userRole = 'customer';
    String? userAvatar;

    if (authState is AuthAuthenticated) {
      userName = authState.user.fullName;
      userRole = authState.user.role;
      userAvatar = authState.user.fullAvatarUrl;
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.scissors, color: AppColors.primary, size: 18),
            const SizedBox(width: 8),
            Text(
              'BARBAR',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(LucideIcons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          const NotificationBellIcon(),
        ],
      ),
      drawer: Drawer(
        backgroundColor: AppColors.background,
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: AppColors.surface),
              currentAccountPicture: CircleAvatar(
                backgroundColor: AppColors.primary,
                backgroundImage: userAvatar != null ? NetworkImage(userAvatar) : null,
                child: userAvatar == null
                    ? const Icon(LucideIcons.user, color: Colors.black, size: 36)
                    : null,
              ),
              accountName: Text(
                userName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              accountEmail: Text(
                'Role: ${userRole.toUpperCase()}',
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w500),
              ),
            ),
            ListTile(
              leading: const Icon(LucideIcons.home, color: AppColors.primary),
              title: const Text('Home Dashboard'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(LucideIcons.shoppingBag, color: AppColors.textSecondary),
              title: const Text('Grooming Products'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (c) => const ShopScreen()));
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.wallet, color: AppColors.textSecondary),
              title: const Text('My Wallet'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (c) => const WalletScreen()));
              },
            ),
            const Divider(color: AppColors.border),
            const Spacer(),
            ListTile(
              leading: const Icon(LucideIcons.logOut, color: AppColors.error),
              title: const Text('Sign Out', style: TextStyle(color: AppColors.error)),
              onTap: () {
                context.read<AuthBloc>().add(LogoutRequested());
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _fetchBarbers();
          context.read<DirectoryBloc>().add(const FetchCategories());
        },
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Greeting & Live Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back,',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        userName,
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 24),
                      ),
                    ],
                  ),
                  _buildLiveBadge(),
                ],
              ),
              const SizedBox(height: 24),

              // Active booking card
              _buildActiveQueueTrackerWidget(),
              const SizedBox(height: 24),

              // Search bar + Map button
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        _fetchBarbers();
                      },
                      decoration: const InputDecoration(
                        hintText: 'Search salons, styling services...',
                        prefixIcon: Icon(LucideIcons.search, size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: IconButton(
                      icon: const Icon(LucideIcons.map, color: AppColors.primary),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (c) => const MapDiscoveryScreen()),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Categories + Filters
              _buildCategoriesAndFilters(),
              const SizedBox(height: 24),

              // Nearby Salons Title
              Text(
                'Nearby Styling Partners',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),

              // Salon List
              BlocBuilder<DirectoryBloc, DirectoryState>(
                builder: (context, state) {
                  if (state is DirectoryLoading) {
                    return _buildLoadingShimmer();
                  } else if (state is DirectoryLoaded) {
                    final barbers = state.barbers;
                    if (barbers.isEmpty) {
                      return _buildEmptyState();
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: barbers.length,
                      itemBuilder: (context, index) {
                        return _buildBarberCard(barbers[index]);
                      },
                    );
                  } else if (state is DirectoryFailure) {
                    return _buildErrorState(state.error);
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesAndFilters() {
    return BlocBuilder<DirectoryBloc, DirectoryState>(
      builder: (context, state) {
        final categories = state is DirectoryLoaded ? state.categories : <CategoryModel>[];
        final selectedCategory = state is DirectoryLoaded ? state.selectedCategory : null;
        final isLoading = state is DirectoryLoaded && state.isCategoriesLoading;
        final catError = state is DirectoryLoaded ? state.categoriesError : null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Chips
            if (isLoading)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text('Loading categories...', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              )
            else if (catError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () => context.read<DirectoryBloc>().add(const FetchCategories()),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.alertCircle, size: 14, color: AppColors.error),
                      const SizedBox(width: 6),
                      Text('Retry categories', style: TextStyle(color: AppColors.error, fontSize: 12)),
                    ],
                  ),
                ),
              )
            else if (categories.isNotEmpty)
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _buildCategoryChip(null, 'All', selectedCategory == null);
                    }
                    final cat = categories[index - 1];
                    return _buildCategoryChip(cat, cat.name, selectedCategory?.id == cat.id);
                  },
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () => context.read<DirectoryBloc>().add(const FetchCategories()),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.refreshCw, size: 14, color: AppColors.primary),
                      SizedBox(width: 6),
                      Text('Load categories', style: TextStyle(color: AppColors.primary, fontSize: 12)),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 12),

            // Rating + Open Now Filters
            Row(
              children: [
                _buildFilterChip('3+', _selectedMinRating == 3.0, () {
                  setState(() {
                    _selectedMinRating = _selectedMinRating == 3.0 ? null : 3.0;
                  });
                  _fetchBarbers();
                }),
                const SizedBox(width: 8),
                _buildFilterChip('4+', _selectedMinRating == 4.0, () {
                  setState(() {
                    _selectedMinRating = _selectedMinRating == 4.0 ? null : 4.0;
                  });
                  _fetchBarbers();
                }),
                const SizedBox(width: 8),
                _buildFilterChip('5+', _selectedMinRating == 5.0, () {
                  setState(() {
                    _selectedMinRating = _selectedMinRating == 5.0 ? null : 5.0;
                  });
                  _fetchBarbers();
                }),
                const SizedBox(width: 12),
                _buildToggleChip('Open Now', _openNow, () {
                  setState(() {
                    _openNow = !_openNow;
                  });
                  _fetchBarbers();
                }),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategoryChip(CategoryModel? category, String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        context.read<DirectoryBloc>().add(SetSelectedCategory(category));
        _fetchBarbers(categoryId: category?.id);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star, size: 14, color: isSelected ? Colors.black : AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.black : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleChip(String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppColors.success.withValues(alpha: 0.15) : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? AppColors.success : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.clock, size: 14, color: isActive ? AppColors.success : AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? AppColors.success : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _isLiveSynced
            ? AppColors.success.withValues(alpha: 0.12)
            : AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isLiveSynced
              ? AppColors.success.withValues(alpha: 0.4)
              : AppColors.warning.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isLiveSynced ? AppColors.success : AppColors.warning,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            _isLiveSynced ? 'LIVE SYNC' : 'OFFLINE',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: _isLiveSynced ? AppColors.success : AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveQueueTrackerWidget() {
    return BlocConsumer<BookingBloc, BookingState>(
      listener: (context, state) {
        if (state is BookingsLoaded) {
          final active = state.bookings.cast<BookingModel?>().firstWhere(
            (b) => b!.status == 'confirmed' || b!.status == 'in_progress',
            orElse: () => null,
          );
          if (active?.id != _activeBooking?.id) {
            setState(() => _activeBooking = active);
          }
        }
      },
      builder: (context, state) {
        BookingModel? currentActive = _activeBooking;
        
        if (state is BookingsLoaded) {
          currentActive = state.bookings.cast<BookingModel?>().firstWhere(
            (b) => b!.status == 'confirmed' || b!.status == 'in_progress',
            orElse: () => null,
          );
        }

        if (currentActive == null) return const SizedBox.shrink();

        final booking = currentActive;
        final ahead = booking.queuePosition > 1 ? booking.queuePosition - 1 : 0;

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => QueueTrackerScreen(webSocketClient: widget.webSocketClient),
              ),
            );
          },
          child: GlassCard(
            padding: const EdgeInsets.all(20),
            opacity: 0.12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'YOUR ACTIVE QUEUE',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1.5,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        booking.status.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking.shopName.isNotEmpty ? booking.shopName : 'Barber Shop',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            booking.services.map((s) => s.name).join(', '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '#${booking.queuePosition}',
                          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            color: AppColors.primary,
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Text('Queue Spot', style: TextStyle(fontSize: 10)),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 24, color: AppColors.border),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(LucideIcons.users, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Text('$ahead clients ahead of you'),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(LucideIcons.clock, size: 16, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          '~${booking.estimatedWaitMinutes} Mins wait',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBarberCard(BarberModel barber) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BarberDetailScreen(barber: barber),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 140,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: barber.fullShopImage ?? '',
                      fit: BoxFit.cover,
                      errorWidget: (context, _, __) => Container(
                        color: AppColors.surface,
                        child: const Icon(LucideIcons.scissors, color: AppColors.textSecondary, size: 40),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              barber.rating.toStringAsFixed(1),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            barber.shopName,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
                          ),
                        ),
                        Text(
                          barber.isAvailable ? 'AVAILABLE' : 'CLOSED',
                          style: TextStyle(
                            color: barber.isAvailable ? AppColors.success : AppColors.error,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      barber.shopDescription ?? '',
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(LucideIcons.mapPin, size: 14, color: AppColors.textMuted),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            barber.address,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24, color: AppColors.border),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(LucideIcons.users, size: 16, color: AppColors.textSecondary),
                            const SizedBox(width: 6),
                            Text(
                              '${barber.currentQueueLength} in queue',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(LucideIcons.clock, size: 14, color: AppColors.primary),
                              const SizedBox(width: 6),
                              Text(
                                '~${barber.averageWaitTime.toInt()} mins wait',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
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

  Widget _buildLoadingShimmer() {
    return Shimmer.fromColors(
      baseColor: AppColors.cardBg,
      highlightColor: AppColors.surface,
      child: Column(
        children: List.generate(2, (index) => Container(
          height: 240,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        )),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            const Icon(LucideIcons.scissors, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 12),
            const Text('No salons found in your location radius'),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _fetchBarbers,
              icon: const Icon(LucideIcons.refreshCw, size: 16),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            const Icon(LucideIcons.alertCircle, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.error),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _fetchBarbers,
              icon: const Icon(LucideIcons.refreshCw, size: 16),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
