import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/network/websocket_client.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/repositories/barber_repository.dart';
import '../bloc/booking/booking_bloc.dart';
import '../bloc/booking/booking_event.dart';

import 'barber_dashboard_screen.dart';
import 'barber_bookings_screen.dart';
import 'barber_clients_screen.dart';
import 'barber_more_screen.dart';

class BarberDashboardShell extends StatefulWidget {
  final WebSocketClient webSocketClient;
  final BarberRepository barberRepository;
  final int initialTab;

  const BarberDashboardShell({
    super.key,
    required this.webSocketClient,
    required this.barberRepository,
    this.initialTab = 0,
  });

  @override
  State<BarberDashboardShell> createState() => _BarberDashboardShellState();
}

class _BarberDashboardShellState extends State<BarberDashboardShell> {
  late int _selectedTab;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
    context.read<BookingBloc>().add(FetchBarberBookings());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedTab,
        children: [
          BarberDashboardScreen(
            webSocketClient: widget.webSocketClient,
            barberRepository: widget.barberRepository,
          ),
          const BarberBookingsScreen(),
          const BarberClientsScreen(),
          BarberMoreScreen(barberRepository: widget.barberRepository),
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
          if (index == 0 || index == 1 || index == 2) {
            context.read<BookingBloc>().add(FetchBarberBookings());
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(LucideIcons.layoutDashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(LucideIcons.calendarDays), label: 'Bookings'),
          BottomNavigationBarItem(icon: Icon(LucideIcons.users), label: 'Clients'),
          BottomNavigationBarItem(icon: Icon(LucideIcons.menu), label: 'More'),
        ],
      ),
    );
  }
}
