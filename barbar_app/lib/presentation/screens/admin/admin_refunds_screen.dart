import 'package:barbar_app/presentation/bloc/admin/admin_finance_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/admin/admin_empty_state.dart';
import '../../widgets/admin/admin_error_state.dart';
import '../../widgets/admin/admin_loading_state.dart';

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
    if (currentStatus != 'pending') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Only pending refunds can be processed')));
      return;
    }
    final amountController = TextEditingController(text: amount.toStringAsFixed(2));
    final notesController = TextEditingController();
    final action = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Process Refund', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController, 
              decoration: const InputDecoration(labelText: 'Amount', border: OutlineInputBorder()), 
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesController, 
              decoration: const InputDecoration(labelText: 'Notes', border: OutlineInputBorder()), 
              maxLines: 2,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, 'rejected'), child: const Text('Reject', style: TextStyle(color: AppColors.error))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.black),
            onPressed: () => Navigator.pop(ctx, 'completed'), 
            child: const Text('Approve & Complete')
          ),
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
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: AppColors.error));
        }
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.black,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _chip('All', null),
                  _chip('Pending', 'pending'),
                  _chip('Approved', 'approved'),
                  _chip('Rejected', 'rejected'),
                  _chip('Completed', 'completed'),
                ],
              ),
            ),
          ),
          Expanded(
            child: BlocBuilder<AdminFinanceBloc, AdminFinanceState>(
              builder: (context, state) {
                if (state is AdminFinanceLoading) return const AdminLoadingState();
                if (state is RefundsLoaded) {
                  if (state.refunds.isEmpty) return const AdminEmptyState(icon: LucideIcons.receipt, title: 'No refunds found');
                  return RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () async { _page = 1; _load(); },
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: state.refunds.length,
                      itemBuilder: (_, i) {
                        final r = state.refunds[i];
                        final rId = r['id'] as String? ?? '';
                        final amount = (r['refund_amount'] as num?)?.toDouble() ?? 0.0;
                        final status = r['status'] as String? ?? '';
                        final reason = r['reason'] as String? ?? '';
                        final customerName = r['customer']?['full_name'] as String? ?? 'Guest';
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          color: AppColors.surface,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: status == 'completed' || status == 'processed' ? AppColors.success.withOpacity(0.2) : status == 'rejected' ? AppColors.error.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: status == 'completed' || status == 'processed' ? AppColors.success : status == 'rejected' ? AppColors.error : Colors.orange)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(reason, style: TextStyle(fontSize: 14, color: Colors.grey[300])),
                                const SizedBox(height: 12),
                                const Divider(color: AppColors.border),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    const Text('Amount:', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                                    const Spacer(),
                                    Text('₹', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                                    const SizedBox(width: 16),
                                    if (status == 'pending')
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 12)),
                                        icon: const Icon(LucideIcons.checkCircle, size: 16),
                                        label: const Text('Process'),
                                        onPressed: () => _showProcessDialog(rId, status, amount),
                                      ),
                                  ],
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
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label, style: TextStyle(fontSize: 12, color: sel ? Colors.black : Colors.white)),
        selected: sel,
        selectedColor: AppColors.primary,
        backgroundColor: AppColors.surface,
        checkmarkColor: Colors.black,
        onSelected: (_) { setState(() => _selectedStatus = status); _page = 1; _load(); },
      ),
    );
  }
}
