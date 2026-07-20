import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_theme.dart';

class DeliveryPendingScreen extends StatelessWidget {
  const DeliveryPendingScreen({super.key});

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
                  color: AppColors.warning.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.clock, size: 64, color: AppColors.warning),
              ),
              const SizedBox(height: 32),
              const Text(
                'Verification Pending',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Text(
                'Your documents are under review.\nWe will notify you once your profile is verified.\n\nThis usually takes 24-48 hours.',
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary.withValues(alpha: 0.8)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Icon(LucideIcons.fileCheck, size: 24, color: AppColors.textSecondary.withValues(alpha: 0.5)),
              const SizedBox(height: 8),
              Text(
                'Documents submitted:\nPAN Card • Driving License',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary.withValues(alpha: 0.5)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
