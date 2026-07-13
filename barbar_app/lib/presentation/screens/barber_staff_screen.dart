import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_theme.dart';
import '../bloc/barber_staff/barber_staff_bloc.dart';
import '../bloc/barber_staff/barber_staff_event.dart';
import '../bloc/barber_staff/barber_staff_state.dart';
import '../widgets/glass_card.dart';
import '../../data/models/staff_model.dart';

class BarberStaffScreen extends StatefulWidget {
  const BarberStaffScreen({super.key});

  @override
  State<BarberStaffScreen> createState() => _BarberStaffScreenState();
}

class _BarberStaffScreenState extends State<BarberStaffScreen> {
  @override
  void initState() {
    super.initState();
    context.read<BarberStaffBloc>().add(FetchStaff());
  }

  void _showAddEditStaffDialog({StaffModel? staff}) {
    final nameCtrl = TextEditingController(text: staff?.name ?? '');
    final phoneCtrl = TextEditingController(text: staff?.phone ?? '');
    final startTimeCtrl = TextEditingController(text: staff?.startTime ?? '09:00');
    final endTimeCtrl = TextEditingController(text: staff?.endTime ?? '18:00');
    final workingDaysCtrl = TextEditingController(text: staff?.workingDays ?? 'Mon,Tue,Wed,Thu,Fri,Sat');
    final dayOffCtrl = TextEditingController(text: staff?.dayOff ?? 'Sun');
    String selectedRole = staff?.role ?? 'staff';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              title: Text(staff == null ? 'Add Staff Member' : 'Edit Staff Member'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Name', prefixIcon: Icon(LucideIcons.user)),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: phoneCtrl,
                      decoration: const InputDecoration(labelText: 'Phone', prefixIcon: Icon(LucideIcons.phone)),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: startTimeCtrl,
                            decoration: const InputDecoration(labelText: 'Start Time', prefixIcon: Icon(LucideIcons.clock)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: endTimeCtrl,
                            decoration: const InputDecoration(labelText: 'End Time', prefixIcon: Icon(LucideIcons.clock)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: workingDaysCtrl,
                      decoration: const InputDecoration(labelText: 'Working Days', prefixIcon: Icon(LucideIcons.calendar)),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: dayOffCtrl,
                      decoration: const InputDecoration(labelText: 'Day Off', prefixIcon: Icon(LucideIcons.calendarOff)),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedRole,
                      decoration: const InputDecoration(labelText: 'Role', prefixIcon: Icon(LucideIcons.briefcase)),
                      items: const [
                        DropdownMenuItem(value: 'staff', child: Text('Staff')),
                        DropdownMenuItem(value: 'manager', child: Text('Manager')),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedRole = val);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () {
                    if (nameCtrl.text.trim().isEmpty) return;
                    if (staff == null) {
                      context.read<BarberStaffBloc>().add(AddStaff({
                        'name': nameCtrl.text.trim(),
                        'phone': phoneCtrl.text.trim(),
                        'role': selectedRole,
                        'is_active': true,
                        'start_time': startTimeCtrl.text.trim(),
                        'end_time': endTimeCtrl.text.trim(),
                        'working_days': workingDaysCtrl.text.trim(),
                        'day_off': dayOffCtrl.text.trim(),
                      }));
                    } else {
                      context.read<BarberStaffBloc>().add(UpdateStaff(staff.id, {
                        'name': nameCtrl.text.trim(),
                        'phone': phoneCtrl.text.trim(),
                        'role': selectedRole,
                        'start_time': startTimeCtrl.text.trim(),
                        'end_time': endTimeCtrl.text.trim(),
                        'working_days': workingDaysCtrl.text.trim(),
                        'day_off': dayOffCtrl.text.trim(),
                      }));
                    }
                    Navigator.pop(context);
                  },
                  child: Text(staff == null ? 'Add' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStaffCard(StaffModel staff) {
    return Dismissible(
      key: Key(staff.id),
      direction: staff.isActive ? DismissDirection.endToStart : DismissDirection.none,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.error,
        child: const Icon(LucideIcons.archive, color: Colors.white),
      ),
      onDismissed: (_) {
        context.read<BarberStaffBloc>().add(ArchiveStaff(staff.id));
      },
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primary.withOpacity(0.2),
              backgroundImage: staff.image != null && staff.image!.isNotEmpty ? NetworkImage(staff.image!) : null,
              child: staff.image == null || staff.image!.isEmpty ? const Icon(LucideIcons.user, color: AppColors.primary) : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(staff.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: staff.role == 'manager' ? AppColors.warning.withOpacity(0.2) : AppColors.info.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          staff.role.toUpperCase(),
                          style: TextStyle(fontSize: 10, color: staff.role == 'manager' ? AppColors.warning : AppColors.info, fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (!staff.isActive) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.error.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                          child: const Text('ARCHIVED', style: TextStyle(fontSize: 10, color: AppColors.error, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (staff.phone != null && staff.phone!.isNotEmpty)
                    Text(staff.phone!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(LucideIcons.star, size: 12, color: AppColors.warning),
                      const SizedBox(width: 4),
                      Text('${staff.rating} (${staff.reviewCount})', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(LucideIcons.edit, size: 20),
              onPressed: () => _showAddEditStaffDialog(staff: staff),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('STAFF MANAGEMENT'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.plus),
            onPressed: () => _showAddEditStaffDialog(),
          ),
        ],
      ),
      body: BlocConsumer<BarberStaffBloc, BarberStaffState>(
        listener: (context, state) {
          if (state is BarberStaffOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: AppColors.success));
          } else if (state is BarberStaffError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: AppColors.error));
          }
        },
        builder: (context, state) {
          if (state is BarberStaffLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          } else if (state is BarberStaffLoaded) {
            if (state.staffMembers.isEmpty) {
              return const Center(child: Text('No staff members found. Add one above!'));
            }
            final activeStaff = state.staffMembers.where((s) => s.isActive).toList();
            final archivedStaff = state.staffMembers.where((s) => !s.isActive).toList();

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (activeStaff.isNotEmpty) ...[
                  const Text('ACTIVE STAFF', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1.2)),
                  const SizedBox(height: 12),
                  ...activeStaff.map((s) => _buildStaffCard(s)),
                  const SizedBox(height: 20),
                ],
                if (archivedStaff.isNotEmpty) ...[
                  const Text('ARCHIVED STAFF', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1.2)),
                  const SizedBox(height: 12),
                  ...archivedStaff.map((s) => _buildStaffCard(s)),
                ],
              ],
            );
          }
          return const Center(child: Text('Failed to load staff'));
        },
      ),
    );
  }
}
