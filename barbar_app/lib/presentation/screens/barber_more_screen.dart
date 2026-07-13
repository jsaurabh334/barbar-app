import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/repositories/barber_repository.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_event.dart';

import 'barber_profile_screen.dart';
import 'barber_services_screen.dart';
import 'barber_availability_screen.dart';
import 'barber_documents_screen.dart';
import 'barber_home_service_screen.dart';
import 'barber_earnings_screen.dart';
import 'barber_reviews_screen.dart';
import 'barber_staff_screen.dart';
import 'barber_notifications_screen.dart';
import '../widgets/glass_card.dart';

class BarberMoreScreen extends StatelessWidget {
  final BarberRepository barberRepository;

  const BarberMoreScreen({super.key, required this.barberRepository});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('MORE'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GlassCard(
              child: Column(
                children: [
                  _buildListTile(context, icon: LucideIcons.user, title: 'Shop Profile', screen: BarberProfileScreen(barberRepository: barberRepository)),
                  const Divider(height: 1, color: AppColors.border),
                  _buildListTile(context, icon: LucideIcons.clock, title: 'Availability', screen: const BarberAvailabilityScreen()),
                  const Divider(height: 1, color: AppColors.border),
                  _buildListTile(context, icon: LucideIcons.scissors, title: 'Services', screen: const BarberServicesScreen()),
                  const Divider(height: 1, color: AppColors.border),
                  _buildListTile(context, icon: LucideIcons.home, title: 'Home Service', screen: const BarberHomeServiceScreen()),
                  const Divider(height: 1, color: AppColors.border),
                  _buildListTile(context, icon: LucideIcons.users, title: 'Staff Management', screen: const BarberStaffScreen()),
                  const Divider(height: 1, color: AppColors.border),
                  _buildListTile(context, icon: LucideIcons.bell, title: 'Notifications', screen: const BarberNotificationsScreen()),
                ],
              ),
            ),
            const SizedBox(height: 24),
            GlassCard(
              child: Column(
                children: [
                  _buildListTile(context, icon: LucideIcons.indianRupee, title: 'Earnings & Payouts', screen: const BarberEarningsScreen()),
                  const Divider(height: 1, color: AppColors.border),
                  _buildListTile(context, icon: LucideIcons.star, title: 'Reviews', screen: const BarberReviewsScreen()),
                  const Divider(height: 1, color: AppColors.border),
                  _buildListTile(context, icon: LucideIcons.fileText, title: 'Documents', screen: const BarberDocumentsScreen()),
                ],
              ),
            ),
            const SizedBox(height: 24),
            GlassCard(
              child: ListTile(
                leading: const Icon(LucideIcons.logOut, color: AppColors.error),
                title: const Text('Logout', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w500)),
                trailing: const Icon(LucideIcons.chevronRight, size: 16, color: AppColors.textMuted),
                onTap: () {
                  context.read<AuthBloc>().add(LogoutRequested());
                },
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildListTile(BuildContext context, {required IconData icon, required String title, required Widget screen}) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: const Icon(LucideIcons.chevronRight, size: 16, color: AppColors.textMuted),
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
      },
    );
  }
}
