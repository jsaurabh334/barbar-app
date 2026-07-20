import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';

class DeliverySuspendedScreen extends StatelessWidget {
  final String? reason;

  const DeliverySuspendedScreen({super.key, this.reason});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.shieldAlert, size: 64, color: AppColors.error),
              ),
              const SizedBox(height: 32),
              const Text(
                'Account Suspended',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Text(
                'Your delivery partner account has been suspended.\n\n'
                'Please contact support for assistance.\n'
                'support@barbarapp.com',
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary.withValues(alpha: 0.8)),
                textAlign: TextAlign.center,
              ),
              if (reason != null && reason!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(reason!, style: const TextStyle(color: AppColors.textSecondary), textAlign: TextAlign.center),
                ),
              ],
              const SizedBox(height: 32),
              OutlinedButton.icon(
                onPressed: () => context.read<AuthBloc>().add(LogoutRequested()),
                icon: const Icon(LucideIcons.logOut),
                label: const Text('Logout', style: TextStyle(fontSize: 16)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
