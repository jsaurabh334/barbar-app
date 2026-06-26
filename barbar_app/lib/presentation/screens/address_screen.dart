import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_theme.dart';

class AddressModel {
  final String id;
  final String title;
  final String street;
  final String city;
  final String postalCode;

  AddressModel({
    required this.id,
    required this.title,
    required this.street,
    required this.city,
    required this.postalCode,
  });
}

class AddressScreen extends StatefulWidget {
  final Function(AddressModel) onAddressSelected;

  const AddressScreen({super.key, required this.onAddressSelected});

  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  final List<AddressModel> _savedAddresses = [
    AddressModel(id: 'addr-1', title: 'Home', street: '123 Main Road, Indiranagar', city: 'Bengaluru', postalCode: '560038'),
    AddressModel(id: 'addr-2', title: 'Office', street: '45 Lavelle Road, Richmond Town', city: 'Bengaluru', postalCode: '560001'),
  ];

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _zipController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _zipController.dispose();
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
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _savedAddresses.length,
        itemBuilder: (context, index) {
          final addr = _savedAddresses[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.surface,
                child: Icon(LucideIcons.mapPin, color: AppColors.primary),
              ),
              title: Text(addr.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${addr.street}, ${addr.city} - ${addr.postalCode}'),
              onTap: () {
                widget.onAddressSelected(addr);
                Navigator.pop(context);
              },
            ),
          );
        },
      ),
    );
  }

  void _showAddAddressSheet(BuildContext context) {
    _titleController.clear();
    _streetController.clear();
    _cityController.clear();
    _zipController.clear();

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
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Address Label (e.g. Home, Office)',
                      prefixIcon: Icon(LucideIcons.tag),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Title required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _streetController,
                    decoration: const InputDecoration(
                      labelText: 'Street details',
                      prefixIcon: Icon(LucideIcons.map),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Street details required' : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _cityController,
                          decoration: const InputDecoration(
                            labelText: 'City',
                          ),
                          validator: (v) => v == null || v.isEmpty ? 'City required' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _zipController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Zip Code',
                          ),
                          validator: (v) => v == null || v.length < 5 ? 'Zip invalid' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState?.validate() ?? false) {
                        setState(() {
                          _savedAddresses.add(
                            AddressModel(
                              id: 'addr-${DateTime.now().millisecondsSinceEpoch}',
                              title: _titleController.text.trim(),
                              street: _streetController.text.trim(),
                              city: _cityController.text.trim(),
                              postalCode: _zipController.text.trim(),
                            ),
                          );
                        });
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
}
