import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/delivery_partner_model.dart';
import '../../../domain/repositories/delivery_repository.dart';
import '../delivery_dashboard_screen.dart';
import 'delivery_pending_screen.dart';
import 'delivery_rejected_screen.dart';
import 'delivery_registration_screen.dart';
import 'delivery_suspended_screen.dart';

class DeliveryShell extends StatefulWidget {
  const DeliveryShell({super.key});

  @override
  State<DeliveryShell> createState() => _DeliveryShellState();
}

class _DeliveryShellState extends State<DeliveryShell> {
  bool _checking = true;
  DeliveryPartnerModel? _profile;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkProfile();
  }

  Future<void> _checkProfile() async {
    setState(() { _checking = true; _error = null; });
    final repo = context.read<DeliveryRepository>();
    try {
      final profile = await repo.getProfile();
      if (mounted) setState(() { _profile = profile; _checking = false; });
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('404') || msg.contains('not found')) {
        if (mounted) setState(() { _profile = null; _checking = false; });
      } else {
        if (mounted) setState(() { _error = msg; _checking = false; });
      }
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

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.alertCircle, size: 48, color: AppColors.error),
                const SizedBox(height: 16),
                Text('Error loading profile: $_error',
                    style: const TextStyle(color: Colors.white), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _checkProfile,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_profile == null) {
      return const DeliveryRegistrationScreen();
    }

    switch (_profile!.status) {
      case 'pending':
        return const DeliveryPendingScreen();
      case 'rejected':
        return DeliveryRejectedScreen(rejectionReason: _profile!.rejectionReason);
      case 'suspended':
        return DeliverySuspendedScreen(reason: _profile!.rejectionReason);
      case 'approved':
      default:
        return const DeliveryDashboardScreen();
    }
  }
}
