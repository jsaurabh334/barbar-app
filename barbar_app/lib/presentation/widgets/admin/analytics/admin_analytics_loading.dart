import 'package:flutter/material.dart';
import 'package:barbar_app/core/theme/app_theme.dart';

class AdminAnalyticsLoading extends StatelessWidget {
  const AdminAnalyticsLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 16),
            Text('Loading analytics...', style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
