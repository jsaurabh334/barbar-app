import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_theme.dart';
import '../bloc/barber_availability/barber_availability_bloc.dart';
import '../bloc/barber_availability/barber_availability_event.dart';
import '../bloc/barber_availability/barber_availability_state.dart';
import '../widgets/glass_card.dart';

class BarberAvailabilityScreen extends StatefulWidget {
  const BarberAvailabilityScreen({super.key});

  @override
  State<BarberAvailabilityScreen> createState() => _BarberAvailabilityScreenState();
}

class _BarberAvailabilityScreenState extends State<BarberAvailabilityScreen> {
  static const dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  final _holidayDateController = TextEditingController();
  final _holidayReasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<BarberAvailabilityBloc>().add(FetchAvailability());
  }

  @override
  void dispose() {
    _holidayDateController.dispose();
    _holidayReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AVAILABILITY')),
      body: BlocConsumer<BarberAvailabilityBloc, BarberAvailabilityState>(
        listener: (context, state) {
          if (state is BarberAvailabilitySuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColors.success),
            );
          } else if (state is BarberAvailabilityFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error), backgroundColor: AppColors.error),
            );
          }
        },
        builder: (context, state) {
          if (state is BarberAvailabilityLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          final loaded = state is BarberAvailabilityLoaded ? state : null;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildStatusSelector(loaded),
                const SizedBox(height: 24),
                _buildWeeklySchedule(loaded),
                const SizedBox(height: 24),
                _buildBreakTimeSection(loaded),
                const SizedBox(height: 24),
                _buildHolidaysSection(loaded),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusSelector(BarberAvailabilityLoaded? loaded) {
    final currentStatus = loaded?.currentStatus ?? 'active';
    final statuses = [
      {'key': 'active', 'label': 'Online', 'icon': LucideIcons.globe, 'color': AppColors.success},
      {'key': 'busy', 'label': 'Busy', 'icon': LucideIcons.clock, 'color': AppColors.warning},
      {'key': 'on_break', 'label': 'Break', 'icon': LucideIcons.coffee, 'color': AppColors.info},
      {'key': 'closed', 'label': 'Offline', 'icon': LucideIcons.xCircle, 'color': AppColors.error},
    ];

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('CURRENT STATUS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: statuses.map((s) {
              final isSelected = (s['key'] as String) == currentStatus;
              return GestureDetector(
                onTap: () {
                  context.read<BarberAvailabilityBloc>().add(
                    UpdateStatus(
                      status: s['key'] as String,
                      isAvailable: s['key'] == 'active',
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? (s['color'] as Color).withValues(alpha: 0.15) : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isSelected ? s['color'] as Color : AppColors.border),
                  ),
                  child: Column(
                    children: [
                      Icon(s['icon'] as IconData, color: isSelected ? s['color'] as Color : AppColors.textSecondary, size: 22),
                      const SizedBox(height: 4),
                      Text(
                        s['label'] as String,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? s['color'] as Color : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklySchedule(BarberAvailabilityLoaded? loaded) {
    final schedule = loaded?.weeklySchedule ?? [];

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('WEEKLY SCHEDULE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary)),
          const SizedBox(height: 16),
          ...List.generate(7, (i) {
            final daySchedule = schedule.where((s) => s['day_of_week'] == i).toList();
            final hasSchedule = daySchedule.isNotEmpty;
            final start = hasSchedule ? daySchedule.first['start_time'] as String? ?? '09:00' : '09:00';
            final end = hasSchedule ? daySchedule.first['end_time'] as String? ?? '21:00' : '21:00';
            final active = hasSchedule ? daySchedule.first['is_active'] as bool? ?? true : true;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(width: 40, child: Text(dayNames[i], style: const TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildTimeDropdown(start, (val) {
                            _updateDaySchedule(i, val, end, active);
                          }),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Text('-', style: TextStyle(color: AppColors.textSecondary)),
                        ),
                        Expanded(
                          child: _buildTimeDropdown(end, (val) {
                            _updateDaySchedule(i, start, val, active);
                          }),
                        ),
                      ],
                    ),
                  ),
                  Checkbox(
                    value: active,
                    onChanged: (val) {
                      _updateDaySchedule(i, start, end, val ?? true);
                    },
                    fillColor: WidgetStateProperty.resolveWith((states) => active ? AppColors.primary : AppColors.border),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              final updated = List.generate(7, (i) {
                final daySchedule = schedule.where((s) => s['day_of_week'] == i).toList();
                final hasSchedule = daySchedule.isNotEmpty;
                return {
                  'day_of_week': i,
                  'start_time': hasSchedule ? daySchedule.first['start_time'] as String? ?? '09:00' : '09:00',
                  'end_time': hasSchedule ? daySchedule.first['end_time'] as String? ?? '21:00' : '21:00',
                  'is_active': hasSchedule ? daySchedule.first['is_active'] as bool? ?? true : true,
                };
              });
              context.read<BarberAvailabilityBloc>().add(SetWeeklySchedule(updated));
            },
            child: const Text('SAVE SCHEDULE'),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeDropdown(String current, Function(String) onChanged) {
    final times = ['08:00', '09:00', '10:00', '11:00', '12:00', '13:00', '14:00', '15:00',
                   '16:00', '17:00', '18:00', '19:00', '20:00', '21:00', '22:00'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: times.contains(current) ? current : '09:00',
          isExpanded: true,
          dropdownColor: AppColors.surface,
          style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
          items: times.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 12)))).toList(),
          onChanged: (val) { if (val != null) onChanged(val); },
        ),
      ),
    );
  }

  void _updateDaySchedule(int day, String start, String end, bool active) {
    final blocState = context.read<BarberAvailabilityBloc>().state;
    if (blocState is BarberAvailabilityLoaded) {
      final updated = List<Map<String, dynamic>>.from(blocState.weeklySchedule);
      updated.removeWhere((s) => s['day_of_week'] == day);
      updated.add({'day_of_week': day, 'start_time': start, 'end_time': end, 'is_active': active});
      context.read<BarberAvailabilityBloc>().add(UpdateLocalScheduleEvent(updated));
    }
  }

  Widget _buildBreakTimeSection(BarberAvailabilityLoaded? loaded) {
    final start = loaded?.breakStartTime ?? '14:00';
    final end = loaded?.breakEndTime ?? '15:00';

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('BREAK TIME', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTimeDropdown(start, (val) {
                  context.read<BarberAvailabilityBloc>().add(UpdateBreakTime(startTime: val, endTime: end));
                }),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('to', style: TextStyle(color: AppColors.textSecondary)),
              ),
              Expanded(
                child: _buildTimeDropdown(end, (val) {
                  context.read<BarberAvailabilityBloc>().add(UpdateBreakTime(startTime: start, endTime: val));
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHolidaysSection(BarberAvailabilityLoaded? loaded) {
    final holidays = loaded?.holidays ?? [];

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('VACATION / HOLIDAYS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary)),
          const SizedBox(height: 16),
          TextField(
            controller: _holidayDateController,
            readOnly: true,
            decoration: const InputDecoration(
              labelText: 'Date',
              prefixIcon: Icon(LucideIcons.calendar, size: 18),
            ),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now().add(const Duration(days: 1)),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) {
                _holidayDateController.text = picked.toIso8601String().substring(0, 10);
              }
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _holidayReasonController,
            decoration: const InputDecoration(
              labelText: 'Reason',
              prefixIcon: Icon(LucideIcons.fileText, size: 18),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              if (_holidayDateController.text.isNotEmpty && _holidayReasonController.text.isNotEmpty) {
                context.read<BarberAvailabilityBloc>().add(
                  AddHoliday(date: _holidayDateController.text, reason: _holidayReasonController.text),
                );
                _holidayDateController.clear();
                _holidayReasonController.clear();
              }
            },
            child: const Text('ADD HOLIDAY'),
          ),
          if (holidays.isNotEmpty) ...[
            const SizedBox(height: 16),
            ...holidays.map((h) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(LucideIcons.calendarX, size: 16, color: AppColors.warning),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${h['date']?.toString().substring(0, 10) ?? ''} - ${h['reason'] as String? ?? ''}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }
}
