import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/network/websocket_client.dart';
import '../../core/theme/app_theme.dart';
import 'home_screen.dart';
import 'shop_screen.dart';
import 'queue_tracker_screen.dart';
import 'wallet_screen.dart';

class CustomerDashboardShell extends StatefulWidget {
  final WebSocketClient webSocketClient;

  const CustomerDashboardShell({super.key, required this.webSocketClient});

  @override
  State<CustomerDashboardShell> createState() => _CustomerDashboardShellState();
}

class _CustomerDashboardShellState extends State<CustomerDashboardShell> {
  int _selectedTab = 0;
  late final List<Widget> _views;

  @override
  void initState() {
    super.initState();
    _views = [
      HomeScreen(webSocketClient: widget.webSocketClient),
      const ShopScreen(),
      QueueTrackerScreen(webSocketClient: widget.webSocketClient),
      const WalletScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedTab,
        children: _views,
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
          BottomNavigationBarItem(icon: Icon(LucideIcons.clock), label: 'Live Queue'),
          BottomNavigationBarItem(icon: Icon(LucideIcons.wallet), label: 'Wallet'),
        ],
      ),
    );
  }
}
