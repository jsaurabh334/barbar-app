import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';
import '../../data/models/barber_model.dart';
import '../../core/network/websocket_client.dart';
import '../../core/theme/app_theme.dart';
import 'map_discovery_screen.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_event.dart';
import '../bloc/auth/auth_state.dart';
import '../bloc/directory/directory_bloc.dart';
import '../bloc/directory/directory_event.dart';
import '../bloc/directory/directory_state.dart';
import '../widgets/glass_card.dart';

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

  @override
  void initState() {
    super.initState();
    
    // Trigger initial fetching of nearby salons (using dummy coordinates for testing)
    context.read<DirectoryBloc>().add(
      const FetchNearbyBarbers(latitude: 12.9716, longitude: 77.5946),
    );

    // Set up WebSocket listeners for real-time queue synchronization
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
      if (event['type'] == 'queue_update') {
        final payload = event['payload'] as Map<String, dynamic>;
        final position = payload['current_position'] as int;
        final waitMin = (payload['estimated_wait_min'] as num).toDouble();
        
        // Trigger queue size updates dynamically in UI BLoC
        context.read<DirectoryBloc>().add(
          UpdateBarberQueue(
            barberId: 'c0a80101-8fc2-11eb-8dcd-0242ac130003', // Map to primary shop for testing
            currentQueueLength: position + 2,
            averageWaitTime: waitMin,
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    widget.webSocketClient.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    String userName = 'Guest';
    String userRole = 'customer';

    if (authState is AuthAuthenticated) {
      userName = authState.user.fullName;
      userRole = authState.user.role;
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
          IconButton(
            icon: const Icon(LucideIcons.bell),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No new notifications')),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: AppColors.background,
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: AppColors.surface),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: AppColors.primary,
                child: Icon(LucideIcons.user, color: Colors.black, size: 36),
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
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(LucideIcons.wallet, color: AppColors.textSecondary),
              title: const Text('My Wallet'),
              onTap: () {},
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
          context.read<DirectoryBloc>().add(
            const FetchNearbyBarbers(latitude: 12.9716, longitude: 77.5946),
          );
        },
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Greeting & Live Status Indicator
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

              // Active booking card mockup if customer has a live queue spot
              _buildActiveQueueTrackerWidget(),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        context.read<DirectoryBloc>().add(
                          FetchNearbyBarbers(
                            latitude: 12.9716,
                            longitude: 77.5946,
                            search: val.isNotEmpty ? val : null,
                          ),
                        );
                      },
                      decoration: const InputDecoration(
                        hintText: 'Search salons, styling services...',
                        prefixIcon: Icon(LucideIcons.search, size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    height: 56, // Match height with standard InputDecoration content padding
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
              const SizedBox(height: 24),

              // Nearby Salons Title
              Text(
                'Nearby Styling Partners',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),

              // Salons List View
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
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Text(
                          state.error,
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ),
                    );
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
    return GlassCard(
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
                child: const Text(
                  'CONFIRMED',
                  style: TextStyle(
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
                      'Premium Barber Shop',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: 4),
                    const Text('Haircut & Hot Towel Shave'),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '#4',
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
              const Row(
                children: [
                  Icon(LucideIcons.users, size: 16, color: AppColors.textSecondary),
                  SizedBox(width: 8),
                  Text('3 clients ahead of you'),
                ],
              ),
              Row(
                children: [
                  const Icon(LucideIcons.clock, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    '~45 Mins wait',
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBarberCard(BarberModel barber) {
    return Container(
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
            // Salon Banner Image
            SizedBox(
              height: 140,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    barber.shopImage ?? '',
                    fit: BoxFit.cover,
                    errorBuilder: (context, _, __) => Container(
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
            
            // Details Section
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
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(LucideIcons.scissors, size: 48, color: AppColors.textMuted),
            SizedBox(height: 12),
            Text('No salons found in your location radius'),
          ],
        ),
      ),
    );
  }
}
