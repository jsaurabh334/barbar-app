import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import 'delivery_registration_screen.dart';

class DeliveryRejectedScreen extends StatelessWidget {
  final String? rejectionReason;

  const DeliveryRejectedScreen({super.key, this.rejectionReason});

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
                child: const Icon(LucideIcons.xCircle, size: 64, color: AppColors.error),
              ),
              const SizedBox(height: 32),
              const Text(
                'Verification Rejected',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 16),
              if (rejectionReason != null && rejectionReason!.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      const Text('Reason:', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(rejectionReason!, style: const TextStyle(color: Colors.white), textAlign: TextAlign.center),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
              const Text(
                'Please upload correct documents and re-apply.',
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const DeliveryRegistrationScreen()),
                  );
                },
                icon: const Icon(LucideIcons.upload),
                label: const Text('Upload Again', style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.read<AuthBloc>().add(LogoutRequested()),
                child: const Text('Logout', style: TextStyle(color: AppColors.textSecondary)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
