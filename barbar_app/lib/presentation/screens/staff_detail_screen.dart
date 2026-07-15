import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/staff_model.dart';
import '../../data/models/barber_model.dart';
import '../widgets/glass_card.dart';

class StaffDetailScreen extends StatelessWidget {
  final StaffModel staff;
  final BarberModel barber;

  const StaffDetailScreen({
    super.key,
    required this.staff,
    required this.barber,
  });

  String _mapDaysToText(String? days) {
    if (days == null || days.isEmpty) return '';
    final map = {'0': 'Sun', '1': 'Mon', '2': 'Tue', '3': 'Wed', '4': 'Thu', '5': 'Fri', '6': 'Sat'};
    return days.split(',').map((e) => map[e.trim()] ?? e.trim()).join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(staff.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 48,
              backgroundColor: AppColors.primary.withValues(alpha: 0.2),
              backgroundImage: staff.image != null && staff.image!.isNotEmpty ? NetworkImage(staff.image!) : null,
              child: staff.image == null || staff.image!.isEmpty
                  ? const Icon(LucideIcons.user, size: 40, color: AppColors.primary)
                  : null,
            ),
            const SizedBox(height: 16),
            Text(staff.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.star, size: 18, color: AppColors.warning),
                const SizedBox(width: 4),
                Text(staff.ratingDisplay, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                Text(' (${staff.reviewCount} reviews)', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              ],
            ),
            const SizedBox(height: 6),
            Text(staff.roleLabel, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
            const SizedBox(height: 32),

            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _detailSection(LucideIcons.briefcase, 'Experience', '${staff.experienceYears} years'),
                  if (staff.languages.isNotEmpty) ...[
                    const Divider(height: 24, color: AppColors.border),
                    _detailSection(LucideIcons.globe, 'Languages', staff.languages.join(', ')),
                  ],
                  if (staff.bio != null && staff.bio!.isNotEmpty) ...[
                    const Divider(height: 24, color: AppColors.border),
                    _detailSection(LucideIcons.info, 'About', staff.bio!),
                  ],
                  if (staff.specializations != null && staff.specializations!.isNotEmpty) ...[
                    const Divider(height: 24, color: AppColors.border),
                    _detailSection(LucideIcons.scissors, 'Specializations', staff.specializations!),
                  ],
                  const Divider(height: 24, color: AppColors.border),
                  _detailSection(LucideIcons.clock, 'Working Hours', '${staff.startTime ?? 'N/A'} - ${staff.endTime ?? 'N/A'}'),
                  if (staff.workingDays != null && staff.workingDays!.isNotEmpty) ...[
                    const Divider(height: 24, color: AppColors.border),
                    _detailSection(LucideIcons.calendar, 'Working Days', _mapDaysToText(staff.workingDays)),
                  ],
                  if (staff.services != null && staff.services!.isNotEmpty) ...[
                    const Divider(height: 24, color: AppColors.border),
                    const Text('Services', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    ...staff.services!.map((s) {
                      final svc = s['service'] as Map<String, dynamic>?;
                      final svcName = svc?['name'] as String? ?? s['service_id'] as String? ?? 'Service';
                      final price = (s['price'] as num?)?.toDouble() ?? 0;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.scissors, size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 8),
                            Expanded(child: Text(svcName, style: const TextStyle(fontSize: 13))),
                            if (price > 0) Text('₹${price.toInt()}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context, staff.id);
                },
                icon: const Icon(LucideIcons.calendarCheck),
                label: Text('Book with ${staff.name}'),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _detailSection(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 12),
        SizedBox(
          width: 100,
          child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 14)),
        ),
      ],
    );
  }
}
