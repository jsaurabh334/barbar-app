import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/repositories/delivery_repository.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_state.dart';

class DeliveryVerificationScreen extends StatefulWidget {
  const DeliveryVerificationScreen({super.key});

  @override
  State<DeliveryVerificationScreen> createState() => _DeliveryVerificationScreenState();
}

class _DeliveryVerificationScreenState extends State<DeliveryVerificationScreen> {
  Map<String, dynamic>? _partnerData;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPartnerData();
  }

  Future<void> _loadPartnerData() async {
    try {
      final presence = await context.read<DeliveryRepository>().getMyPresence();
      if (mounted) {
        setState(() {
          _partnerData = presence;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthBloc>().state is AuthAuthenticated
        ? (context.watch<AuthBloc>().state as AuthAuthenticated).user
        : null;

    final vehicleType = (_partnerData?['vehicle_type'] as String?)?.toUpperCase() ?? '—';
    final vehicleNumber = (_partnerData?['vehicle_number'] as String?) ?? '—';
    final licenseNumber = (_partnerData?['license_number'] as String?) ?? '—';
    final status = (_partnerData?['status'] as String?) ?? '—';

    return Scaffold(
      appBar: AppBar(
        title: const Text('License & Vehicle Verification', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            color: Colors.greenAccent,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(LucideIcons.checkCheck, color: Colors.black, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${status.toUpperCase()} PARTNER',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.greenAccent),
                              ),
                              const SizedBox(height: 4),
                              const Text('All documents & background checks verified by Admin.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('VERIFIED CREDENTIALS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.5, color: AppColors.textSecondary)),
                  const SizedBox(height: 12),
                  _buildTile('Full Name', user?.fullName ?? '—', LucideIcons.user),
                  _buildTile('Phone Number', user?.phone ?? '—', LucideIcons.phone),
                  _buildTile('Vehicle Type', vehicleType, LucideIcons.bike),
                  _buildTile('Registration Number', vehicleNumber, LucideIcons.shieldCheck),
                  _buildTile('Driving License No.', licenseNumber, LucideIcons.fileText),
                ],
              ),
            ),
    );
  }

  Widget _buildTile(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
            ],
          ),
        ],
      ),
    );
  }
}

