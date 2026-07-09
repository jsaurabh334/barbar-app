import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/network/websocket_client.dart';
import '../../core/theme/app_theme.dart';
import 'booking_history_screen.dart';
import 'home_screen.dart';
import 'queue_tracker_screen.dart';
import 'shop_screen.dart';
import 'profile_screen.dart';

class CustomerDashboardShell extends StatefulWidget {
  final WebSocketClient webSocketClient;

  const CustomerDashboardShell({super.key, required this.webSocketClient});

  @override
  State<CustomerDashboardShell> createState() => _CustomerDashboardShellState();
}

class _CustomerDashboardShellState extends State<CustomerDashboardShell> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedTab,
        children: [
          HomeScreen(webSocketClient: widget.webSocketClient),
          const ShopScreen(),
          const BookingHistoryScreen(),
          QueueTrackerScreen(webSocketClient: widget.webSocketClient),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTab,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        backgroundColor: AppColors.surface,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _selectedTab = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(LucideIcons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(LucideIcons.shoppingBag), label: 'Shop'),
          BottomNavigationBarItem(icon: Icon(LucideIcons.calendar), label: 'My Bookings'),
          BottomNavigationBarItem(icon: Icon(LucideIcons.clock), label: 'Live Queue'),
          BottomNavigationBarItem(icon: Icon(LucideIcons.user), label: 'Profile'),
        ],
      ),
    );
  }
}
