import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_theme.dart';
import '../bloc/barber_services/barber_services_bloc.dart';
import '../bloc/barber_services/barber_services_event.dart';
import '../bloc/barber_services/barber_services_state.dart';
import '../widgets/glass_card.dart';

class BarberServicesScreen extends StatefulWidget {
  const BarberServicesScreen({super.key});

  @override
  State<BarberServicesScreen> createState() => _BarberServicesScreenState();
}

class _BarberServicesScreenState extends State<BarberServicesScreen> {
  @override
  void initState() {
    super.initState();
    context.read<BarberServicesBloc>().add(FetchServices());
  }

  void _showAddEditDialog([Map<String, dynamic>? service]) {
    final nameController = TextEditingController(text: service?['name'] as String?);
    final descController = TextEditingController(text: service?['description'] as String?);
    final categoryController = TextEditingController(text: service?['category']?['name'] as String?);
    final priceController = TextEditingController(text: service != null ? service['price'].toString() : '');
    final defPriceController = TextEditingController(text: service?['default_price']?.toString() ?? '');
    final durationController = TextEditingController(text: service != null ? service['duration_minutes'].toString() : '');
    final defDurationController = TextEditingController(text: service?['default_duration_minutes']?.toString() ?? '');
    final bufferController = TextEditingController(text: service?['default_buffer_minutes']?.toString() ?? '');
    bool isAddon = service?['is_addon'] as bool? ?? false;
    bool isActive = service?['is_active'] as bool? ?? true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              title: Text(service == null ? 'Add Service' : 'Edit Service'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
                    const SizedBox(height: 12),
                    TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description')),
                    const SizedBox(height: 12),
                    TextField(controller: categoryController, decoration: const InputDecoration(labelText: 'Category')),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: priceController, decoration: const InputDecoration(labelText: 'Price'), keyboardType: TextInputType.number)),
                        const SizedBox(width: 12),
                        Expanded(child: TextField(controller: defPriceController, decoration: const InputDecoration(labelText: 'Default Price'), keyboardType: TextInputType.number)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: durationController, decoration: const InputDecoration(labelText: 'Duration (min)'), keyboardType: TextInputType.number)),
                        const SizedBox(width: 12),
                        Expanded(child: TextField(controller: defDurationController, decoration: const InputDecoration(labelText: 'Default Duration'), keyboardType: TextInputType.number)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(controller: bufferController, decoration: const InputDecoration(labelText: 'Default Buffer (min)'), keyboardType: TextInputType.number),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text('Is Addon', style: TextStyle(fontSize: 14)),
                      value: isAddon,
                      onChanged: (val) => setState(() => isAddon = val),
                    ),
                    SwitchListTile(
                      title: const Text('Is Active', style: TextStyle(fontSize: 14)),
                      value: isActive,
                      onChanged: (val) => setState(() => isActive = val),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () {
                    final data = {
                      'name': nameController.text,
                      'description': descController.text,
                      'price': double.tryParse(priceController.text) ?? 0,
                      'default_price': double.tryParse(defPriceController.text),
                      'duration_minutes': int.tryParse(durationController.text) ?? 30,
                      'default_duration_minutes': int.tryParse(defDurationController.text),
                      'default_buffer_minutes': int.tryParse(bufferController.text),
                      'is_addon': isAddon,
                      'is_active': isActive,
                    };
                    if (service == null) {
                      context.read<BarberServicesBloc>().add(AddService(data));
                    } else {
                      context.read<BarberServicesBloc>().add(UpdateService(serviceId: service['id'] as String, data: data));
                    }
                    Navigator.pop(context);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> service) {
    final isActive = service['is_active'] as bool? ?? true;
    return Dismissible(
      key: Key(service['id'] as String),
      direction: DismissDirection.endToStart,
      background: Container(
        color: isActive ? AppColors.warning : AppColors.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Icon(isActive ? LucideIcons.archive : LucideIcons.trash, color: Colors.white),
      ),
      onDismissed: (_) {
        if (isActive) {
          context.read<BarberServicesBloc>().add(ToggleActive(serviceId: service['id'] as String, isActive: false));
        } else {
          context.read<BarberServicesBloc>().add(DeleteService(service['id'] as String));
        }
      },
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(service['name'] as String? ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.edit, color: AppColors.primary, size: 20),
                  onPressed: () => _showAddEditDialog(service),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('₹${service['price']}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                const SizedBox(width: 12),
                Text('${service['duration_minutes']} min', style: const TextStyle(color: AppColors.textSecondary)),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.success.withOpacity(0.2) : AppColors.warning.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(isActive ? 'Active' : 'Archived', style: TextStyle(fontSize: 10, color: isActive ? AppColors.success : AppColors.warning)),
                ),
              ],
            ),
            if (service['description'] != null && (service['description'] as String).isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(service['description'] as String, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
            const SizedBox(height: 12),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.star, color: Colors.amber, size: 14),
                    SizedBox(width: 4),
                    Text('5.0 (24)', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
                Text('12 bookings today', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500)),
              ],
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
        title: const Text('SERVICES'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.plus),
            onPressed: () => _showAddEditDialog(),
          ),
        ],
      ),
      body: BlocConsumer<BarberServicesBloc, BarberServicesState>(
        listener: (context, state) {
          if (state is BarberServicesSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: AppColors.success));
          } else if (state is BarberServicesFailure) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error), backgroundColor: AppColors.error));
          }
        },
        builder: (context, state) {
          if (state is BarberServicesLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          } else if (state is BarberServicesLoaded) {
            final activeServices = state.services.where((s) => s['is_active'] == true).toList();
            final archivedServices = state.services.where((s) => s['is_active'] == false).toList();

            if (state.services.isEmpty) {
              return const Center(child: Text('No services found. Add one!'));
            }

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (activeServices.isNotEmpty) ...[
                  const Text('ACTIVE SERVICES', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary)),
                  const SizedBox(height: 16),
                  ...activeServices.map(_buildServiceCard),
                ],
                if (archivedServices.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const Text('ARCHIVED SERVICES', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.warning)),
                  const SizedBox(height: 16),
                  ...archivedServices.map(_buildServiceCard),
                ],
              ],
            );
          }
          return const Center(child: Text('Failed to load services'));
        },
      ),
    );
  }
}
