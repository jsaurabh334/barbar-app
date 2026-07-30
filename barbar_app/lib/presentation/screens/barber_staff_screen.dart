import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/repositories/barber_repository.dart';
import '../bloc/barber_staff/barber_staff_bloc.dart';
import '../bloc/barber_staff/barber_staff_event.dart';
import '../bloc/barber_staff/barber_staff_state.dart';
import '../widgets/glass_card.dart';
import '../../data/models/staff_model.dart';
import 'barber_staff_profile_screen.dart';

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

  String _mapDaysToText(String? days) {
    if (days == null || days.isEmpty) return '';
    final map = {'0': 'Sun', '1': 'Mon', '2': 'Tue', '3': 'Wed', '4': 'Thu', '5': 'Fri', '6': 'Sat'};
    return days.split(',').map((e) => map[e.trim()] ?? e.trim()).join(',');
  }

  String _mapTextToDays(String text) {
    final map = {'sun': '0', 'mon': '1', 'tue': '2', 'wed': '3', 'thu': '4', 'fri': '5', 'sat': '6'};
    return text.split(',').map((e) => map[e.trim().toLowerCase()] ?? e.trim()).join(',');
  }

  void _showAddEditStaffDialog({StaffModel? staff}) {
    final nameCtrl = TextEditingController(text: staff?.name ?? '');
    final phoneCtrl = TextEditingController(text: staff?.phone ?? '');
    final startTimeCtrl = TextEditingController(text: staff?.startTime ?? '09:00');
    final endTimeCtrl = TextEditingController(text: staff?.endTime ?? '18:00');
    final workingDaysCtrl = TextEditingController(text: staff != null && staff.workingDays != null ? _mapDaysToText(staff.workingDays) : 'Mon,Tue,Wed,Thu,Fri,Sat');
    final dayOffCtrl = TextEditingController(text: staff != null && staff.dayOff != null ? _mapDaysToText(staff.dayOff) : 'Sun');
    String selectedRole = staff?.role ?? 'staff';
    String? currentImageUrl = staff?.image;
    File? pendingImageFile;
    bool isUploadingImage = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> pickImage(ImageSource source) async {
              final picker = ImagePicker();
              try {
                final picked = await picker.pickImage(source: source, imageQuality: 80);
                if (picked != null) {
                  setDialogState(() {
                    pendingImageFile = File(picked.path);
                    isUploadingImage = true;
                  });
                  final repo = context.read<BarberRepository>();
                  final uploadedUrl = await repo.uploadStaffImage(File(picked.path));
                  setDialogState(() {
                    currentImageUrl = uploadedUrl;
                    isUploadingImage = false;
                  });
                }
              } catch (e) {
                setDialogState(() => isUploadingImage = false);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to upload image: $e'), backgroundColor: AppColors.error),
                  );
                }
              }
            }

            return AlertDialog(
              backgroundColor: AppColors.surface,
              title: Text(staff == null ? 'Add Staff Member' : 'Edit Staff Member'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Profile image picker avatar
                    GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: AppColors.surface,
                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
                          builder: (_) => SafeArea(
                            child: Wrap(
                              children: [
                                ListTile(
                                  leading: const Icon(LucideIcons.image, color: AppColors.primary),
                                  title: const Text('Gallery'),
                                  onTap: () {
                                    Navigator.pop(context);
                                    pickImage(ImageSource.gallery);
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(LucideIcons.camera, color: AppColors.primary),
                                  title: const Text('Camera'),
                                  onTap: () {
                                    Navigator.pop(context);
                                    pickImage(ImageSource.camera);
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                            backgroundImage: pendingImageFile != null
                                ? FileImage(pendingImageFile!) as ImageProvider
                                : (currentImageUrl != null && currentImageUrl!.isNotEmpty
                                    ? NetworkImage(StaffModel(id: '', barberId: '', name: '', role: '', isActive: true, rating: 0, reviewCount: 0, image: currentImageUrl).fullImageUrl!)
                                    : null),
                            child: (pendingImageFile == null && (currentImageUrl == null || currentImageUrl!.isEmpty))
                                ? const Icon(LucideIcons.user, size: 36, color: AppColors.primary)
                                : null,
                          ),
                          if (isUploadingImage)
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.5), shape: BoxShape.circle),
                              child: const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2)),
                            )
                          else
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                                child: const Icon(LucideIcons.camera, size: 14, color: Colors.black),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currentImageUrl != null && currentImageUrl!.isNotEmpty ? 'Tap to change photo' : 'Tap to add staff photo',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
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
                  onPressed: isUploadingImage ? null : () {
                    if (nameCtrl.text.trim().isEmpty) return;
                    final Map<String, dynamic> payload = {
                      'name': nameCtrl.text.trim(),
                      'phone': phoneCtrl.text.trim(),
                      'role': selectedRole,
                      'image': currentImageUrl ?? '',
                      'start_time': startTimeCtrl.text.trim(),
                      'end_time': endTimeCtrl.text.trim(),
                      'working_days': _mapTextToDays(workingDaysCtrl.text.trim()),
                      'day_off': _mapTextToDays(dayOffCtrl.text.trim()),
                    };
                    if (staff == null) {
                      payload['is_active'] = true;
                      context.read<BarberStaffBloc>().add(AddStaff(payload));
                    } else {
                      context.read<BarberStaffBloc>().add(UpdateStaff(staff.id, payload));
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
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => BarberStaffProfileScreen(staff: staff)),
            );
          },
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                backgroundImage: staff.fullImageUrl != null ? NetworkImage(staff.fullImageUrl!) : null,
                child: staff.fullImageUrl == null ? const Icon(LucideIcons.user, color: AppColors.primary) : null,
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
                            color: staff.role == 'manager' ? AppColors.warning.withValues(alpha: 0.2) : AppColors.info.withValues(alpha: 0.2),
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
                            decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
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
              const Icon(LucideIcons.chevronRight, size: 20, color: AppColors.textMuted),
            ],
          ),
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
