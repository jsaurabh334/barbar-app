import 'package:barbar_app/presentation/bloc/admin/admin_finance_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AdminTaxSettingsScreen extends StatefulWidget {
  const AdminTaxSettingsScreen({super.key});
  @override
  State<AdminTaxSettingsScreen> createState() => _AdminTaxSettingsScreenState();
}

class _AdminTaxSettingsScreenState extends State<AdminTaxSettingsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AdminFinanceBloc>().add(const LoadTaxSettings());
  }

  Future<void> _showForm([Map<String, dynamic>? existing]) async {
    final nameCtrl = TextEditingController(text: existing?['name'] as String? ?? '');
    final rateCtrl = TextEditingController(text: (existing?['rate'] as num?)?.toString() ?? '');
    final typeCtrl = TextEditingController(text: existing?['type'] as String? ?? 'GST');
    final descCtrl = TextEditingController(text: existing?['description'] as String? ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing != null ? 'Edit Tax Setting' : 'Add Tax Setting'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder())),
            const SizedBox(height: 8),
            TextField(controller: rateCtrl, decoration: const InputDecoration(labelText: 'Rate %', border: OutlineInputBorder()), keyboardType: TextInputType.number),
            const SizedBox(height: 8),
            TextField(controller: typeCtrl, decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder())),
            const SizedBox(height: 8),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()), maxLines: 2),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Back')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty && rateCtrl.text.isNotEmpty) {
                Navigator.pop(ctx, true);
              }
            },
            child: Text(existing != null ? 'Update' : 'Create'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      final data = {
        'name': nameCtrl.text,
        'rate': double.parse(rateCtrl.text),
        'type': typeCtrl.text,
        'description': descCtrl.text,
      };
      if (existing != null) {
        context.read<AdminFinanceBloc>().add(UpdateTaxSetting(existing['id'] as String, data));
      } else {
        context.read<AdminFinanceBloc>().add(CreateTaxSetting(data));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AdminFinanceBloc, AdminFinanceState>(
      listener: (context, state) {
        if (state is AdminFinanceActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
          context.read<AdminFinanceBloc>().add(const LoadTaxSettings());
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Tax Settings'), automaticallyImplyLeading: false, actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: () => _showForm()),
        ]),
        body: BlocBuilder<AdminFinanceBloc, AdminFinanceState>(
          builder: (context, state) {
            if (state is AdminFinanceLoading) return const Center(child: CircularProgressIndicator());
            if (state is TaxSettingsLoaded) {
              final taxes = state.taxSettings;
              if (taxes.isEmpty) return const Center(child: Text('No tax settings'));
              return ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: taxes.length,
                itemBuilder: (_, i) {
                  final t = taxes[i];
                  final name = t['name'] as String? ?? '';
                  final rate = (t['rate'] as num?)?.toDouble() ?? 0.0;
                  final type = t['type'] as String? ?? '';
                  final active = t['is_active'] as bool? ?? true;
                  final id = t['id'] as String? ?? '';
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      title: Text('$name ($type) — ${rate.toStringAsFixed(1)}%', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: Text('ID: $id', style: const TextStyle(fontSize: 11)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!active) Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(color: Colors.grey.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                            child: const Text('inactive', style: TextStyle(fontSize: 10, color: Colors.grey)),
                          ),
                          IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: () => _showForm(t)),
                          IconButton(
                            icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                            onPressed: () => context.read<AdminFinanceBloc>().add(DeleteTaxSetting(id)),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }
            if (state is AdminFinanceError) return Center(child: Text('Error: ${state.message}'));
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
