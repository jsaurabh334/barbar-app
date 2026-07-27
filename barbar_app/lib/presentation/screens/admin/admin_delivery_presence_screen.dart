import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:barbar_app/core/theme/app_theme.dart';
import 'package:barbar_app/domain/repositories/admin_repository.dart';
import 'package:barbar_app/data/models/delivery_partner_model.dart';

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
  List<DeliveryPartnerModel> _partners = [];
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadAllData();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) => _loadAllData());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    final repo = context.read<AdminRepository>();
    try {
      final summary = await repo.getDeliveryPresenceSummary().catchError((_) => <String, dynamic>{});
      final partners = await repo.getDeliveryPartners(page: 1, limit: 50).catchError((_) => <DeliveryPartnerModel>[]);

      if (mounted) {
        setState(() {
          _partners = partners;
          _online = (summary['online'] as num?)?.toInt() ?? 0;
          _busy = (summary['busy'] as num?)?.toInt() ?? 0;
          final redisOffline = (summary['offline'] as num?)?.toInt() ?? 0;
          _offline = redisOffline > 0 ? redisOffline : partners.length;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _updateStatus(String partnerId, String newStatus) async {
    try {
      await context.read<AdminRepository>().updateDeliveryPartnerStatus(partnerId, newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delivery Partner status updated to $newStatus')),
        );
        _loadAllData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Delivery Drivers & Partners', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, color: AppColors.primary, size: 20),
            onPressed: () {
              setState(() => _loading = true);
              _loadAllData();
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _loadAllData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats Row
                    Row(
                      children: [
                        Expanded(child: _buildStatCard('Online', _online, AppColors.success, LucideIcons.wifi)),
                        const SizedBox(width: 10),
                        Expanded(child: _buildStatCard('Busy', _busy, AppColors.warning, LucideIcons.clock)),
                        const SizedBox(width: 10),
                        Expanded(child: _buildStatCard('Registered', _offline, AppColors.textSecondary, LucideIcons.users)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Auto refresh indicator card
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.refreshCw, color: AppColors.primary, size: 16),
                          const SizedBox(width: 10),
                          const Text('Live Sync active', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                          const Spacer(),
                          Text(
                            '${_partners.length} Total Partners',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Registered Delivery Drivers List Header
                    const Row(
                      children: [
                        Icon(LucideIcons.bike, size: 18, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text(
                          'Delivery Driver Profiles',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (_partners.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(32),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Column(
                          children: [
                            Icon(LucideIcons.userX, size: 40, color: AppColors.textMuted),
                            SizedBox(height: 12),
                            Text('No registered delivery partners found.', style: TextStyle(color: AppColors.textSecondary)),
                          ],
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _partners.length,
                        itemBuilder: (context, index) {
                          final p = _partners[index];
                          final name = p.user?.fullName ?? 'Delivery Partner';
                          final phone = p.user?.phone ?? '';
                          final status = p.status.isNotEmpty ? p.status : 'pending';
                          final isApproved = status.toLowerCase() == 'approved';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.cardBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(0.15),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        name.isNotEmpty ? name[0].toUpperCase() : 'D',
                                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
                                          if (phone.isNotEmpty)
                                            Text(phone, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isApproved ? AppColors.success.withOpacity(0.15) : AppColors.warning.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: isApproved ? AppColors.success.withOpacity(0.4) : AppColors.warning.withOpacity(0.4)),
                                      ),
                                      child: Text(
                                        status.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: isApproved ? AppColors.success : AppColors.warning,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Vehicle: ${p.vehicleType.toUpperCase()} (${p.vehicleNumber})',
                                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                        ),
                                      ),
                                      Text(
                                        'License: ${p.licenseNumber}',
                                        style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (!isApproved)
                                      ElevatedButton.icon(
                                        onPressed: () => _updateStatus(p.id, 'approved'),
                                        icon: const Icon(LucideIcons.check, size: 14),
                                        label: const Text('Approve Partner'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.success,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        ),
                                      )
                                    else
                                      OutlinedButton.icon(
                                        onPressed: () => _updateStatus(p.id, 'suspended'),
                                        icon: const Icon(LucideIcons.ban, size: 14, color: AppColors.error),
                                        label: const Text('Suspend', style: TextStyle(color: AppColors.error)),
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(color: AppColors.error),
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard(String label, int count, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            '$count',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 26,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
