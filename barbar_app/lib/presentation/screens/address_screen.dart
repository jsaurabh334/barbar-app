import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_theme.dart';
import '../bloc/address/address_bloc.dart';
import '../bloc/address/address_event.dart';
import '../bloc/address/address_state.dart';

class AddressScreen extends StatefulWidget {
  final void Function(Map<String, dynamic> address) onAddressSelected;

  const AddressScreen({super.key, required this.onAddressSelected});

  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _labelController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _line1Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<AddressBloc>().add(FetchAddresses());
  }

  @override
  void dispose() {
    _labelController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _line1Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MY ADDRESSES'),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.black,
        child: const Icon(LucideIcons.plus),
        onPressed: () => _showAddAddressSheet(context),
      ),
      body: BlocBuilder<AddressBloc, AddressState>(
        builder: (context, state) {
          if (state is AddressLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (state is AddressFailure) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.alertCircle, size: 48, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text(state.error, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => context.read<AddressBloc>().add(FetchAddresses()),
                    icon: const Icon(LucideIcons.refreshCw),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          if (state is AddressesLoaded) {
            final addresses = state.addresses;
            if (addresses.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.mapPin, size: 64, color: AppColors.textSecondary),
                    const SizedBox(height: 16),
                    Text('No saved addresses', style: Theme.of(context).textTheme.bodyLarge),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () => _showAddAddressSheet(context),
                      icon: const Icon(LucideIcons.plus),
                      label: const Text('Add Address'),
                    ),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: addresses.length,
              itemBuilder: (context, index) {
                final addr = addresses[index];
                final label = addr['label'] ?? 'Address';
                final line1 = addr['line_1'] ?? '';
                final city = addr['city'] ?? '';
                final state = addr['state'] ?? '';
                final pincode = addr['pincode'] ?? '';
                final isDefault = addr['is_default'] == true;
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDefault ? AppColors.primary : AppColors.border,
                      width: isDefault ? 2 : 1,
                    ),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isDefault ? AppColors.primary.withValues(alpha: 0.2) : AppColors.surface,
                      child: Icon(
                        isDefault ? LucideIcons.home : LucideIcons.mapPin,
                        color: isDefault ? AppColors.primary : AppColors.textSecondary,
                      ),
                    ),
                    title: Row(
                      children: [
                        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
                        if (isDefault) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('Default', style: TextStyle(fontSize: 11, color: AppColors.primary)),
                          ),
                        ],
                      ],
                    ),
                    subtitle: Text([line1, city, state, pincode].where((e) => e.isNotEmpty).join(', ')),
                    onTap: () {
                      widget.onAddressSelected(addr);
                      Navigator.pop(context);
                    },
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showEditAddressSheet(context, addr);
                        } else if (value == 'set_default') {
                          context.read<AddressBloc>().add(SetDefaultAddress(addr['id'] as String));
                        } else if (value == 'delete') {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Delete Address'),
                              content: const Text('Are you sure you want to delete this address?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    context.read<AddressBloc>().add(DeleteAddress(addr['id'] as String));
                                  },
                                  child: const Text('Delete', style: TextStyle(color: AppColors.error)),
                                ),
                              ],
                            ),
                          );
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                        if (!isDefault)
                          const PopupMenuItem(value: 'set_default', child: Text('Set as Default')),
                        const PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                  ),
                );
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  void _showAddAddressSheet(BuildContext context) {
    _labelController.clear();
    _fullNameController.clear();
    _phoneController.clear();
    _line1Controller.clear();
    _cityController.clear();
    _stateController.clear();
    _pincodeController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'ADD NEW ADDRESS',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.primary),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _labelController,
                    decoration: const InputDecoration(
                      labelText: 'Address Label (e.g. Home, Office)',
                      prefixIcon: Icon(LucideIcons.tag),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Label required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _fullNameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(LucideIcons.user),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Full name required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: Icon(LucideIcons.phone),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Phone required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _line1Controller,
                    decoration: const InputDecoration(
                      labelText: 'Street / Area',
                      prefixIcon: Icon(LucideIcons.map),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Address required' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _cityController,
                          decoration: const InputDecoration(labelText: 'City'),
                          validator: (v) => v == null || v.isEmpty ? 'City required' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _stateController,
                          decoration: const InputDecoration(labelText: 'State'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _pincodeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Pincode'),
                    validator: (v) => v == null || v.length < 6 ? 'Enter valid 6-digit pincode' : null,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState?.validate() ?? false) {
                        context.read<AddressBloc>().add(AddAddress({
                          'label': _labelController.text.trim(),
                          'full_name': _fullNameController.text.trim(),
                          'phone': _phoneController.text.trim(),
                          'line_1': _line1Controller.text.trim(),
                          'city': _cityController.text.trim(),
                          'state': _stateController.text.trim(),
                          'pincode': _pincodeController.text.trim(),
                          'country': 'IN',
                        }));
                        Navigator.pop(context);
                      }
                    },
                    child: const Text('SAVE ADDRESS'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showEditAddressSheet(BuildContext context, Map<String, dynamic> addr) {
    _labelController.text = addr['label'] ?? '';
    _fullNameController.text = addr['full_name'] ?? '';
    _phoneController.text = addr['phone'] ?? '';
    _line1Controller.text = addr['line_1'] ?? '';
    _cityController.text = addr['city'] ?? '';
    _stateController.text = addr['state'] ?? '';
    _pincodeController.text = addr['pincode'] ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'EDIT ADDRESS',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.primary),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _labelController,
                    decoration: const InputDecoration(
                      labelText: 'Address Label (e.g. Home, Office)',
                      prefixIcon: Icon(LucideIcons.tag),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Label required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _fullNameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(LucideIcons.user),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Full name required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: Icon(LucideIcons.phone),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Phone required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _line1Controller,
                    decoration: const InputDecoration(
                      labelText: 'Street / Area',
                      prefixIcon: Icon(LucideIcons.map),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Address required' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _cityController,
                          decoration: const InputDecoration(labelText: 'City'),
                          validator: (v) => v == null || v.isEmpty ? 'City required' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _stateController,
                          decoration: const InputDecoration(labelText: 'State'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _pincodeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Pincode'),
                    validator: (v) => v == null || v.length < 6 ? 'Enter valid 6-digit pincode' : null,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState?.validate() ?? false) {
                        context.read<AddressBloc>().add(UpdateAddress(id: addr['id'] as String, address: {
                          'label': _labelController.text.trim(),
                          'full_name': _fullNameController.text.trim(),
                          'phone': _phoneController.text.trim(),
                          'line_1': _line1Controller.text.trim(),
                          'city': _cityController.text.trim(),
                          'state': _stateController.text.trim(),
                          'pincode': _pincodeController.text.trim(),
                        }));
                        Navigator.pop(context);
                      }
                    },
                    child: const Text('UPDATE ADDRESS'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
