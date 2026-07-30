import 'package:flutter/material.dart';
import '../notifications_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/notification/notification_bloc.dart';

import '../../bloc/notification/notification_state.dart';
import 'vendor_dashboard_screen.dart';
import 'vendor_product_list_screen.dart';
import 'vendor_order_list_screen.dart';
import 'vendor_profile_screen.dart';
import 'vendor_wallet_screen.dart';
import 'vendor_warehouses_screen.dart';
import 'vendor_brands_screen.dart';
import 'vendor_purchase_list_screen.dart';

class VendorMainScreen extends StatefulWidget {
  const VendorMainScreen({super.key});

  @override
  State<VendorMainScreen> createState() => _VendorMainScreenState();
}

class _VendorMainScreenState extends State<VendorMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = [
    const VendorDashboardScreen(),
    const VendorProductListScreen(),
    const VendorOrderListScreen(),
    const VendorWalletScreen(),
    const VendorProfileScreen(),
  ];

  final List<String> _titles = [
    'Seller Dashboard',
    'Inventory',
    'Orders',
    'Wallet',
    'Profile',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(LucideIcons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          BlocBuilder<NotificationBloc, NotificationState>(
            builder: (context, state) {
              int unreadCount = 0;
              if (state is NotificationLoaded) {
                unreadCount = state.unreadCount;
              }
              return IconButton(
                icon: unreadCount > 0 
                  ? Badge(
                      label: Text('$unreadCount'),
                      backgroundColor: AppColors.error,
                      child: const Icon(LucideIcons.bell),
                    )
                  : const Icon(LucideIcons.bell),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: _buildDrawer(context),
      body: _tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.background,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        items: const [
          BottomNavigationBarItem(icon: Icon(LucideIcons.home), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(LucideIcons.briefcase), label: 'Products'),
          BottomNavigationBarItem(icon: Icon(LucideIcons.clipboard), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(LucideIcons.wallet), label: 'Wallet'),
          BottomNavigationBarItem(icon: Icon(LucideIcons.user), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  const Icon(LucideIcons.store, color: AppColors.primary, size: 32),
                  const SizedBox(width: 12),
                  Text('Seller Panel', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const Divider(color: AppColors.border),
            Expanded(
              child: ListView(
                children: [
                  _buildDrawerItem(LucideIcons.home, 'Dashboard', () {
                    Navigator.pop(context);
                    setState(() => _currentIndex = 0);
                  }),
                  _buildDrawerItem(LucideIcons.package, 'Products', () {
                    Navigator.pop(context);
                    setState(() => _currentIndex = 1);
                  }),
                  _buildDrawerItem(LucideIcons.shoppingBag, 'Orders', () {
                    Navigator.pop(context);
                    setState(() => _currentIndex = 2);
                  }),
                  _buildDrawerItem(LucideIcons.warehouse, 'Warehouses', () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const VendorWarehousesScreen()));
                  }),
                  _buildDrawerItem(LucideIcons.tag, 'Brands', () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const VendorBrandsScreen()));
                  }),
                  _buildDrawerItem(LucideIcons.shoppingCart, 'Purchase History', () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const VendorPurchaseListScreen()));
                  }),
                  _buildDrawerItem(LucideIcons.wallet, 'Wallet', () {
                    Navigator.pop(context);
                    setState(() => _currentIndex = 3);
                  }),
                  _buildDrawerItem(LucideIcons.barChart2, 'Analytics', () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Analytics coming soon')),
                    );
                  }),
                  _buildDrawerItem(LucideIcons.user, 'Profile', () {
                    Navigator.pop(context);
                    setState(() => _currentIndex = 4);
                  }),
                ],
              ),
            ),
            const Divider(color: AppColors.border),
            _buildDrawerItem(LucideIcons.logOut, 'Logout', () {
              Navigator.pop(context);
              context.read<AuthBloc>().add(LogoutRequested());
            }, isDestructive: true),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap, {bool isDestructive = false}) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? AppColors.error : AppColors.textSecondary),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? AppColors.error : AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }
}
