import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../bloc/delivery/delivery_bloc.dart';
import '../../bloc/delivery/delivery_event.dart';
import '../../bloc/delivery/delivery_state.dart';
import '../delivery_dashboard_screen.dart';
import 'delivery_pending_screen.dart';
import 'delivery_rejected_screen.dart';
import 'delivery_registration_screen.dart';
import 'delivery_suspended_screen.dart';
import '../../../data/models/delivery_partner_model.dart';

import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';

class DeliveryShell extends StatefulWidget {
  const DeliveryShell({super.key});

  @override
  State<DeliveryShell> createState() => _DeliveryShellState();
}

class _DeliveryShellState extends State<DeliveryShell> {
  DeliveryPartnerModel? _lastProfile;

  @override
  void initState() {
    super.initState();
    context.read<DeliveryBloc>().add(LoadDeliveryProfile());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DeliveryBloc, DeliveryState>(
      builder: (context, state) {
        if (state is DeliveryProfileLoaded) {
          _lastProfile = state.profile;
        }

        if (state is DeliveryInitial || (state is DeliveryLoading && _lastProfile == null)) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 16),
                  Text('Loading delivery profile...', style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            ),
          );
        }

        if (state is DeliveryFailure && _lastProfile == null) {
          final is401 = state.error.contains('401') || state.error.toLowerCase().contains('unauthorized');
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.alertCircle, size: 48, color: AppColors.error),
                    const SizedBox(height: 16),
                    Text(
                      is401 ? 'Session expired. Please log in again.' : 'Error loading profile: ${state.error}',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () => context.read<DeliveryBloc>().add(LoadDeliveryProfile()),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.surface,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Retry'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () => context.read<AuthBloc>().add(LogoutRequested()),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.black,
                          ),
                          child: const Text('Re-login'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (state is DeliveryNoProfile) {
          return const DeliveryRegistrationScreen();
        }

        if (_lastProfile != null) {
          final profile = _lastProfile!;
          switch (profile.status) {
            case 'pending':
              return const DeliveryPendingScreen();
            case 'rejected':
              return DeliveryRejectedScreen(rejectionReason: profile.rejectionReason);
            case 'suspended':
              return DeliverySuspendedScreen(reason: profile.rejectionReason);
            case 'approved':
            default:
              return const DeliveryDashboardScreen();
          }
        }

        return const Scaffold(
          body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
        );
      },
    );
  }
}
