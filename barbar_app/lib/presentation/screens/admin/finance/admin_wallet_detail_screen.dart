import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:barbar_app/core/theme/app_theme.dart';
import 'package:barbar_app/presentation/bloc/admin/admin_wallet_bloc.dart';
import 'package:barbar_app/data/models/settlement_model.dart';

class AdminWalletDetailScreen extends StatefulWidget {
  final WalletAdminModel wallet;
  const AdminWalletDetailScreen({super.key, required this.wallet});

  @override
  State<AdminWalletDetailScreen> createState() => _AdminWalletDetailScreenState();
}

class _AdminWalletDetailScreenState extends State<AdminWalletDetailScreen> {
  final _amountController = TextEditingController();
  final _descController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<AdminWalletBloc>().add(LoadAdminWalletDetail(widget.wallet.id));
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.wallet.ownerName)),
      body: BlocListener<AdminWalletBloc, AdminWalletState>(
        listener: (context, state) {
          if (state is AdminWalletActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: AppColors.success));
            context.read<AdminWalletBloc>().add(LoadAdminWalletDetail(widget.wallet.id));
          } else if (state is AdminWalletError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: AppColors.error));
          }
        },
        child: BlocBuilder<AdminWalletBloc, AdminWalletState>(
          builder: (context, state) {
            final transactions = state is AdminWalletDetailLoaded ? state.transactions : <Map<String, dynamic>>[];
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildBalanceCard(),
                  const SizedBox(height: 20),
                  _buildActionButtons(context),
                  const SizedBox(height: 24),
                  _buildTransactionList(transactions),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.wallet, size: 32, color: AppColors.primary),
              const SizedBox(width: 12),
              Text('₹${widget.wallet.balance.toStringAsFixed(2)}', style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statItem('Locked', '₹${widget.wallet.lockedBalance.toStringAsFixed(2)}', Colors.orange),
              _statItem('Status', widget.wallet.isActive ? 'Active' : 'Frozen', widget.wallet.isActive ? Colors.green : Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16)),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            icon: const Icon(LucideIcons.plusCircle, size: 18),
            label: const Text('Credit', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () => _showAmountDialog(context, 'credit'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            icon: const Icon(LucideIcons.minusCircle, size: 18),
            label: const Text('Debit', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () => _showAmountDialog(context, 'debit'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: widget.wallet.isActive ? AppColors.error : Colors.green,
              side: BorderSide(color: widget.wallet.isActive ? AppColors.error : Colors.green),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            icon: Icon(widget.wallet.isActive ? LucideIcons.snowflake : LucideIcons.thermometer, size: 18),
            label: Text(widget.wallet.isActive ? 'Freeze' : 'Unfreeze', style: const TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () {
              context.read<AdminWalletBloc>().add(ToggleAdminWalletFreeze(widget.wallet.id));
            },
          ),
        ),
      ],
    );
  }

  void _showAmountDialog(BuildContext context, String type) {
    _amountController.clear();
    _descController.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(type == 'credit' ? 'Credit Wallet' : 'Debit Wallet'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount (₹)', prefixText: '₹ '),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(labelText: 'Description (optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(_amountController.text);
              if (amount == null || amount <= 0) return;
              Navigator.pop(ctx);
              if (type == 'credit') {
                context.read<AdminWalletBloc>().add(CreditAdminWallet(
                  id: widget.wallet.id,
                  amount: amount,
                  description: _descController.text.isNotEmpty ? _descController.text : null,
                ));
              } else {
                context.read<AdminWalletBloc>().add(DebitAdminWallet(
                  id: widget.wallet.id,
                  amount: amount,
                  description: _descController.text.isNotEmpty ? _descController.text : null,
                ));
              }
            },
            child: Text(type == 'credit' ? 'CREDIT' : 'DEBIT'),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList(List<Map<String, dynamic>> transactions) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('RECENT TRANSACTIONS', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5, color: AppColors.primary)),
          const Divider(height: 20),
          if (transactions.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: Text('No transactions', style: TextStyle(color: AppColors.textSecondary))),
            )
          else
            ...transactions.map((txn) {
              final type = txn['txn_type'] as String? ?? 'credit';
              final amount = (txn['amount'] as num?)?.toDouble() ?? 0.0;
              final description = txn['description'] as String? ?? '';
              final date = txn['created_at'] as String? ?? '';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Icon(
                      type == 'credit' ? LucideIcons.trendingUp : LucideIcons.trendingDown,
                      color: type == 'credit' ? Colors.green : Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(description.isNotEmpty ? description : (type == 'credit' ? 'Credit' : 'Debit')),
                          Text(_formatDate(date), style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                        ],
                      ),
                    ),
                    Text(
                      '${type == 'credit' ? '+' : '-'}₹${amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: type == 'credit' ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr;
    }
  }
}
