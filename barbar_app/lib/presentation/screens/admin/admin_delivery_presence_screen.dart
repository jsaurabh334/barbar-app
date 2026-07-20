import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:barbar_app/core/theme/app_theme.dart';
import 'package:barbar_app/domain/repositories/admin_repository.dart';

class AdminDeliveryPresenceScreen extends StatefulWidget {
  const AdminDeliveryPresenceScreen({super.key});

  @override
  State<AdminDeliveryPresenceScreen> createState() => _AdminDeliveryPresenceScreenState();
}

class _AdminDeliveryPresenceScreenState extends State<AdminDeliveryPresenceScreen> {
  int _online = 0;
  int _busy = 0;
  int _offline = 0;
  bool _loading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadSummary();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) => _loadSummary());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadSummary() async {
    try {
      final summary = await context.read<AdminRepository>().getDeliveryPresenceSummary();
      if (mounted) {
        setState(() {
          _online = (summary['online'] as num?)?.toInt() ?? 0;
          _busy = (summary['busy'] as num?)?.toInt() ?? 0;
          _offline = (summary['offline'] as num?)?.toInt() ?? 0;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Delivery Drivers')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildStatCard('Online', _online, AppColors.success, LucideIcons.wifi)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildStatCard('Busy', _busy, AppColors.warning, LucideIcons.clock)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildStatCard('Offline', _offline, AppColors.textSecondary, LucideIcons.wifiOff)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.refreshCw, color: AppColors.primary, size: 20),
                        const SizedBox(width: 12),
                        const Text('Auto-refreshes every 10 seconds', style: TextStyle(color: AppColors.textSecondary)),
                        const Spacer(),
                        Text(
                          '${_online + _busy + _offline} total',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(String label, int count, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            '$count',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 32,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
