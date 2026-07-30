import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/staff_model.dart';
import '../../data/models/barber_model.dart';
import '../../domain/repositories/barber_repository.dart';
import '../bloc/barber_staff/barber_staff_bloc.dart';
import '../bloc/barber_staff/barber_staff_event.dart';
import '../bloc/barber_staff/barber_staff_state.dart';
import '../bloc/barber_services/barber_services_bloc.dart';
import '../bloc/barber_services/barber_services_event.dart';
import '../bloc/barber_services/barber_services_state.dart';
import '../widgets/glass_card.dart';

class BarberStaffProfileScreen extends StatefulWidget {
  final StaffModel staff;

  const BarberStaffProfileScreen({super.key, required this.staff});

  @override
  State<BarberStaffProfileScreen> createState() => _BarberStaffProfileScreenState();
}

class _BarberStaffProfileScreenState extends State<BarberStaffProfileScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _bioCtrl;
  late TextEditingController _experienceCtrl;
  late TextEditingController _specializationsCtrl;
  late TextEditingController _instagramCtrl;
  late TextEditingController _startTimeCtrl;
  late TextEditingController _endTimeCtrl;
  late TextEditingController _workingDaysCtrl;
  late TextEditingController _dayOffCtrl;
  late TextEditingController _languagesCtrl;
  List<String> _selectedServiceIds = [];
  bool _isEditing = false;
  String? _currentImageUrl;
  File? _pendingImageFile;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    context.read<BarberServicesBloc>().add(FetchServices());
    _initControllers(widget.staff);
  }

  void _initControllers(StaffModel staff) {
    _nameCtrl = TextEditingController(text: staff.name);
    _phoneCtrl = TextEditingController(text: staff.phone ?? '');
    _bioCtrl = TextEditingController(text: staff.bio ?? '');
    _experienceCtrl = TextEditingController(text: staff.experienceYears.toString());
    _specializationsCtrl = TextEditingController(text: staff.specializations ?? '');
    _instagramCtrl = TextEditingController(text: staff.instagram ?? '');
    _startTimeCtrl = TextEditingController(text: staff.startTime ?? '09:00');
    _endTimeCtrl = TextEditingController(text: staff.endTime ?? '21:00');
    _workingDaysCtrl = TextEditingController(text: _mapDaysToText(staff.workingDays));
    _dayOffCtrl = TextEditingController(text: _mapDaysToText(staff.dayOff));
    _languagesCtrl = TextEditingController(text: staff.languages.join(', '));
    _selectedServiceIds = staff.services?.map((s) => s['service_id'].toString()).toList() ?? [];
    _currentImageUrl = staff.image;
    _pendingImageFile = null;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _bioCtrl.dispose();
    _experienceCtrl.dispose();
    _specializationsCtrl.dispose();
    _instagramCtrl.dispose();
    _startTimeCtrl.dispose();
    _endTimeCtrl.dispose();
    _workingDaysCtrl.dispose();
    _dayOffCtrl.dispose();
    _languagesCtrl.dispose();
    super.dispose();
  }

  String _mapDaysToText(String? days) {
    if (days == null || days.isEmpty) return '';
    final map = {'0': 'Sun', '1': 'Mon', '2': 'Tue', '3': 'Wed', '4': 'Thu', '5': 'Fri', '6': 'Sat'};
    return days.split(',').map((e) => map[e.trim()] ?? e.trim()).join(', ');
  }

  String _mapTextToDays(String text) {
    final map = {'sun': '0', 'mon': '1', 'tue': '2', 'wed': '3', 'thu': '4', 'fri': '5', 'sat': '6'};
    return text.split(',').map((e) => map[e.trim().toLowerCase()] ?? e.trim()).join(',');
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(LucideIcons.image, color: AppColors.primary),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(LucideIcons.camera, color: AppColors.primary),
              title: const Text('Take a Photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final picked = await picker.pickImage(source: source, imageQuality: 80);
    if (picked == null) return;

    setState(() {
      _pendingImageFile = File(picked.path);
      _isUploadingImage = true;
    });

    try {
      final repo = context.read<BarberRepository>();
      final url = await repo.uploadStaffImage(File(picked.path));
      setState(() {
        _currentImageUrl = url;
        _isUploadingImage = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Staff profile photo updated!'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      setState(() => _isUploadingImage = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload photo: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _save() {
    context.read<BarberStaffBloc>().add(UpdateStaff(widget.staff.id, {
      'name': _nameCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'image': _currentImageUrl ?? '',
      'bio': _bioCtrl.text.trim(),
      'experience_years': int.tryParse(_experienceCtrl.text.trim()) ?? 0,
      'languages': _languagesCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      'specializations': _specializationsCtrl.text.trim(),
      'instagram': _instagramCtrl.text.trim(),
      'start_time': _startTimeCtrl.text.trim(),
      'end_time': _endTimeCtrl.text.trim(),
      'working_days': _mapTextToDays(_workingDaysCtrl.text.trim()),
      'day_off': _mapTextToDays(_dayOffCtrl.text.trim()),
      'service_ids': _selectedServiceIds,
    }));
    setState(() => _isEditing = false);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BarberStaffBloc, BarberStaffState>(
      builder: (context, state) {
        StaffModel staff = widget.staff;
        if (state is BarberStaffLoaded) {
          staff = state.staffMembers.firstWhere((s) => s.id == widget.staff.id, orElse: () => widget.staff);
        }

        final activeImage = _currentImageUrl ?? staff.image;
        final displayUrl = activeImage != null && activeImage.isNotEmpty
            ? BarberModel.getFullImageUrl(activeImage)
            : null;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(_isEditing ? 'Edit Profile' : staff.name),
            actions: [
              IconButton(
                icon: Icon(_isEditing ? LucideIcons.check : LucideIcons.edit),
                onPressed: _isUploadingImage
                    ? null
                    : () {
                        if (_isEditing) {
                          _save();
                        } else {
                          _initControllers(staff);
                          setState(() => _isEditing = true);
                        }
                      },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                GestureDetector(
                  onTap: _isEditing ? _pickAndUploadImage : null,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                        backgroundImage: _pendingImageFile != null
                            ? FileImage(_pendingImageFile!) as ImageProvider
                            : (displayUrl != null ? NetworkImage(displayUrl) : null),
                        child: (_pendingImageFile == null && displayUrl == null)
                            ? const Icon(LucideIcons.user, size: 40, color: AppColors.primary)
                            : null,
                      ),
                      if (_isUploadingImage)
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.5), shape: BoxShape.circle),
                          child: const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2)),
                        )
                      else if (_isEditing)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                            child: const Icon(LucideIcons.camera, size: 16, color: Colors.black),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                if (_isEditing)
                  const Text('Tap photo to update staff image', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 16),
                if (!_isEditing) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(staff.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: staff.role == 'manager' ? AppColors.warning.withValues(alpha: 0.2) : AppColors.info.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          staff.roleLabel.toUpperCase(),
                          style: TextStyle(fontSize: 11, color: staff.role == 'manager' ? AppColors.warning : AppColors.info, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.star, size: 16, color: AppColors.warning),
                      const SizedBox(width: 4),
                      Text(staff.ratingDisplay, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      Text(' (${staff.reviewCount})', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 32),
                  GlassCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _profileField(LucideIcons.info, 'Bio', staff.bio ?? 'No bio added yet'),
                        const Divider(height: 24, color: AppColors.border),
                        _profileField(LucideIcons.briefcase, 'Experience', '${staff.experienceYears} years'),
                        const Divider(height: 24, color: AppColors.border),
                        _profileField(LucideIcons.globe, 'Languages', staff.languages.isNotEmpty ? staff.languages.join(', ') : 'Not specified'),
                        const Divider(height: 24, color: AppColors.border),
                        _profileField(LucideIcons.scissors, 'Specializations', staff.specializations ?? 'Not specified'),
                        const Divider(height: 24, color: AppColors.border),
                        _profileField(LucideIcons.clock, 'Working Hours', '${staff.startTime ?? 'N/A'} - ${staff.endTime ?? 'N/A'}'),
                        const Divider(height: 24, color: AppColors.border),
                        _profileField(LucideIcons.calendar, 'Working Days', _mapDaysToText(staff.workingDays)),
                        const Divider(height: 24, color: AppColors.border),
                        _profileField(LucideIcons.instagram, 'Instagram', staff.instagram ?? 'Not added'),
                        const Divider(height: 24, color: AppColors.border),
                        _profileField(LucideIcons.checkSquare, 'Assigned Services', _getAssignedServicesText(staff)),
                      ],
                    ),
                  ),
                ] else ...[
                  _buildEditForm(),
                ],
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getAssignedServicesText(StaffModel staff) {
    if (staff.services == null || staff.services!.isEmpty) return 'No services assigned';
    return staff.services!.map((s) => s['service']?['name'] ?? 'Unknown Service').join(', ');
  }

  Widget _profileField(IconData icon, String label, String value) {
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

  Widget _buildEditForm() {
    return Column(
      children: [
        TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Name', prefixIcon: Icon(LucideIcons.user))),
        const SizedBox(height: 16),
        TextField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: 'Phone', prefixIcon: Icon(LucideIcons.phone)), keyboardType: TextInputType.phone),
        const SizedBox(height: 16),
        TextField(controller: _bioCtrl, decoration: const InputDecoration(labelText: 'Bio', prefixIcon: Icon(LucideIcons.info)), maxLines: 3),
        const SizedBox(height: 16),
        TextField(controller: _experienceCtrl, decoration: const InputDecoration(labelText: 'Experience (years)', prefixIcon: Icon(LucideIcons.briefcase)), keyboardType: TextInputType.number),
        const SizedBox(height: 16),
        TextField(controller: _languagesCtrl, decoration: const InputDecoration(labelText: 'Languages (comma separated)', prefixIcon: Icon(LucideIcons.globe))),
        const SizedBox(height: 16),
        TextField(controller: _specializationsCtrl, decoration: const InputDecoration(labelText: 'Specializations', prefixIcon: Icon(LucideIcons.scissors))),
        const SizedBox(height: 16),
        TextField(controller: _instagramCtrl, decoration: const InputDecoration(labelText: 'Instagram', prefixIcon: Icon(LucideIcons.instagram))),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: TextField(controller: _startTimeCtrl, decoration: const InputDecoration(labelText: 'Start Time', prefixIcon: Icon(LucideIcons.clock)))),
            const SizedBox(width: 8),
            Expanded(child: TextField(controller: _endTimeCtrl, decoration: const InputDecoration(labelText: 'End Time', prefixIcon: Icon(LucideIcons.clock)))),
          ],
        ),
        const SizedBox(height: 16),
        TextField(controller: _workingDaysCtrl, decoration: const InputDecoration(labelText: 'Working Days', prefixIcon: Icon(LucideIcons.calendar))),
        const SizedBox(height: 16),
        TextField(controller: _dayOffCtrl, decoration: const InputDecoration(labelText: 'Day Off', prefixIcon: Icon(LucideIcons.calendarOff))),
        const SizedBox(height: 24),
        
        // Assigned Services Section
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(LucideIcons.checkSquare, size: 18, color: AppColors.primary),
                  SizedBox(width: 12),
                  Text('Assign Services', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              const SizedBox(height: 8),
              BlocBuilder<BarberServicesBloc, BarberServicesState>(
                builder: (context, state) {
                  if (state is BarberServicesLoaded) {
                    if (state.services.isEmpty) {
                      return const Text('No services found in shop.', style: TextStyle(color: AppColors.textSecondary));
                    }
                    return Column(
                      children: state.services.map((svc) {
                        final id = svc['id'].toString();
                        return CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(svc['name']?.toString() ?? 'Service'),
                          value: _selectedServiceIds.contains(id),
                          activeColor: AppColors.primary,
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _selectedServiceIds.add(id);
                              } else {
                                _selectedServiceIds.remove(id);
                              }
                            });
                          },
                        );
                      }).toList(),
                    );
                  }
                  return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                },
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _save,
            child: const Text('Save Profile'),
          ),
        ),
      ],
    );
  }
}
