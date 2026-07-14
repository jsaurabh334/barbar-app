import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:barbar_app/domain/repositories/barber_repository.dart';
import 'package:barbar_app/core/network/websocket_client.dart';
import 'package:barbar_app/presentation/bloc/barber_profile/barber_profile_bloc.dart';
import 'package:barbar_app/presentation/screens/barber_dashboard_shell.dart';
import 'package:barbar_app/presentation/screens/barber_profile_screen.dart';
import 'package:barbar_app/presentation/screens/barber/shop_setup_screen.dart';
import 'package:barbar_app/core/theme/app_theme.dart';

class BarberShell extends StatefulWidget {
  final WebSocketClient webSocketClient;

  const BarberShell({Key? key, required this.webSocketClient}) : super(key: key);

  @override
  State<BarberShell> createState() => _BarberShellState();
}

class _BarberShellState extends State<BarberShell> {
  bool _checking = true;
  bool _profileExists = false;
  bool _profileCompleted = false;

  @override
  void initState() {
    super.initState();
    _checkProfile();
  }

  Future<void> _checkProfile() async {
    final barberRepo = context.read<BarberRepository>();
    try {
      final result = await barberRepo.getProfile();
      final completed = result['profile_completed'] as bool? ?? false;
      if (mounted) setState(() { _profileExists = true; _profileCompleted = completed; _checking = false; });
    } catch (e) {
      if (mounted) setState(() { _profileExists = false; _profileCompleted = false; _checking = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 16),
              Text('Loading...', style: TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        ),
      );
    }

    if (!_profileExists) {
      return ShopSetupScreen(webSocketClient: widget.webSocketClient);
    }

    final barberRepo = context.read<BarberRepository>();
    final wsClient = widget.webSocketClient;

    // Even if profile is not completed, we want the user to reach the dashboard 
    // so they can access the Services and Staff pages to complete it.

    return BarberDashboardShell(
      webSocketClient: wsClient,
      barberRepository: barberRepo,
    );
  }
}
