import 'package:barbar_app/presentation/bloc/admin/admin_finance_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AdminRefundsScreen extends StatefulWidget {
  const AdminRefundsScreen({super.key});
  @override
  State<AdminRefundsScreen> createState() => _AdminRefundsScreenState();
}

class _AdminRefundsScreenState extends State<AdminRefundsScreen> {
  String? _selectedStatus;
  int _page = 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    context.read<AdminFinanceBloc>().add(LoadRefunds(page: _page, status: _selectedStatus));
  }

  Future<void> _showProcessDialog(String refundId, String currentStatus, double amount) async {
    final amountController = TextEditingController(text: amount.toStringAsFixed(2));
    final notesController = TextEditingController();
    final action = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Process Refund'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: amountController, decoration: const InputDecoration(labelText: 'Amount', border: OutlineInputBorder()), keyboardType: TextInputType.number),
            const SizedBox(height: 8),
            TextField(controller: notesController, decoration: const InputDecoration(labelText: 'Notes', border: OutlineInputBorder()), maxLines: 2),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, 'rejected'), child: const Text('Reject', style: TextStyle(color: Colors.red))),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, 'processed'), child: const Text('Approve & Process')),
        ],
      ),
    );
    if (action != null && mounted) {
      context.read<AdminFinanceBloc>().add(ProcessRefund(
        refundId, action, amount: double.tryParse(amountController.text), notes: notesController.text,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AdminFinanceBloc, AdminFinanceState>(
      listener: (context, state) {
        if (state is AdminFinanceActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
          _page = 1;
          _load();
        } else if (state is AdminFinanceError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.red));
        }
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.grey[100],
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _chip('All', null),
                  _chip('pending', 'pending'),
                  _chip('approved', 'approved'),
                  _chip('rejected', 'rejected'),
                  _chip('processed', 'processed'),
                ],
              ),
            ),
          ),
          Expanded(
            child: BlocBuilder<AdminFinanceBloc, AdminFinanceState>(
              builder: (context, state) {
                if (state is AdminFinanceLoading) return const Center(child: CircularProgressIndicator());
                if (state is RefundsLoaded) {
                  if (state.refunds.isEmpty) return const Center(child: Text('No refunds'));
                  return RefreshIndicator(
                    onRefresh: () async { _page = 1; _load(); },
                    child: ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: state.refunds.length,
                      itemBuilder: (_, i) {
                        final r = state.refunds[i];
                        final rId = r['id'] as String? ?? '';
                        final amount = (r['refund_amount'] as num?)?.toDouble() ?? 0.0;
                        final status = r['status'] as String? ?? '';
                        final reason = r['reason'] as String? ?? '';
                        final customerName = r['customer']?['full_name'] as String? ?? 'Guest';
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            title: Text('₹${amount.toStringAsFixed(2)} — $customerName', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            subtitle: Text('$reason\nID: $rId', style: const TextStyle(fontSize: 11)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: status == 'processed' ? Colors.green.withOpacity(0.15) : status == 'rejected' ? Colors.red.withOpacity(0.15) : Colors.orange.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(status, style: TextStyle(fontSize: 11, color: status == 'processed' ? Colors.green : status == 'rejected' ? Colors.red : Colors.orange)),
                                ),
                                if (status == 'pending')
                                  IconButton(
                                    icon: const Icon(Icons.verified, size: 20),
                                    onPressed: () => _showProcessDialog(rId, status, amount),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, String? status) {
    final sel = _selectedStatus == status;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: sel,
        onSelected: (_) { setState(() => _selectedStatus = status); _page = 1; _load(); },
      ),
    );
  }
}
