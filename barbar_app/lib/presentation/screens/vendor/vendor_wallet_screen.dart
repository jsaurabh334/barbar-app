import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/repositories/vendor_repository.dart';
import '../../bloc/wallet/wallet_bloc.dart';
import '../../bloc/wallet/wallet_event.dart';
import '../../bloc/wallet/wallet_state.dart';

class VendorWalletScreen extends StatefulWidget {
  const VendorWalletScreen({super.key});

  @override
  State<VendorWalletScreen> createState() => _VendorWalletScreenState();
}

class _VendorWalletScreenState extends State<VendorWalletScreen> {
  final _amountController = TextEditingController();
  List<Map<String, dynamic>> _bankAccounts = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WalletBloc>().add(FetchWalletDetails());
      context.read<WalletBloc>().add(FetchWithdrawals());
      _loadBankAccounts();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadBankAccounts() async {
    try {
      final repo = context.read<VendorRepository>();
      final accounts = await repo.getBankAccounts();
      if (mounted) {
        setState(() => _bankAccounts = accounts);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('WALLET & PAYOUTS')),
      body: BlocConsumer<WalletBloc, WalletState>(
        listener: (context, state) {
          if (state is WithdrawalSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Withdrawal request submitted! Updated balance: \u20B9${state.newBalance.toInt()}'),
                backgroundColor: AppColors.success,
              ),
            );
            context.read<WalletBloc>().add(FetchWithdrawals());
          } else if (state is WalletFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error), backgroundColor: AppColors.error),
            );
          }
        },
        builder: (context, state) {
          if (state is WalletLoading && state is! WalletLoaded) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          } else if (state is WalletLoaded) {
            return RefreshIndicator(
              onRefresh: () async {
                context.read<WalletBloc>().add(FetchWalletDetails());
                context.read<WalletBloc>().add(FetchWithdrawals());
                await _loadBankAccounts();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildBalanceCard(state.balance),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Transaction Ledger', LucideIcons.history),
                    const SizedBox(height: 12),
                    if (state.transactions.isEmpty)
                      _buildEmptyState('No transactions yet.')
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: state.transactions.length,
                        itemBuilder: (_, i) => _buildTransactionItem(state.transactions[i]),
                      ),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Withdrawal History', LucideIcons.arrowUpRight),
                    const SizedBox(height: 12),
                    if (state.withdrawals.isEmpty)
                      _buildEmptyState('No withdrawal requests yet.')
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: state.withdrawals.length,
                        itemBuilder: (_, i) => _buildWithdrawalItem(state.withdrawals[i] as Map<String, dynamic>),
                      ),
                  ],
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildBalanceCard(double balance) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF1A237E), Color(0xFF283593), Color(0xFF0D1B2A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('VENDOR WALLET', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              Icon(LucideIcons.wallet, color: Colors.white70, size: 22),
            ],
          ),
          const SizedBox(height: 24),
          const Text('AVAILABLE BALANCE', style: TextStyle(color: Colors.white60, fontSize: 11, letterSpacing: 1)),
          const SizedBox(height: 4),
          Text('\u20B9${balance.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
          const SizedBox(height: 32),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: () => _showWithdrawDialog(context, balance),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.arrowUpRight, size: 16),
                SizedBox(width: 8),
                Text('REQUEST WITHDRAWAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        Icon(icon, color: AppColors.textSecondary, size: 20),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(child: Text(message, style: const TextStyle(color: AppColors.textSecondary, fontSize: 16))),
    );
  }

  Widget _buildTransactionItem(dynamic tx) {
    final isCredit = tx.type == 'credit' || tx.type == 'refund';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isCredit ? AppColors.success.withValues(alpha: 0.12) : AppColors.error.withValues(alpha: 0.12),
          child: Icon(isCredit ? LucideIcons.arrowDownLeft : LucideIcons.arrowUpRight, color: isCredit ? AppColors.success : AppColors.error, size: 18),
        ),
        title: Text(tx.description, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        subtitle: Text(tx.createdAt.split('T').first, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('${isCredit ? "+" : "-"}\u20B9${tx.amount.toInt()}', style: TextStyle(color: isCredit ? AppColors.success : AppColors.error, fontWeight: FontWeight.w900, fontSize: 15)),
            const SizedBox(height: 2),
            Text(tx.status.toUpperCase(), style: TextStyle(color: tx.status == 'settled' ? AppColors.textMuted : AppColors.warning, fontSize: 9, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildWithdrawalItem(Map<String, dynamic> w) {
    final status = (w['status'] as String? ?? 'pending').toUpperCase();
    final amount = (w['amount'] as num?)?.toDouble() ?? 0;
    final netAmount = (w['net_amount'] as num?)?.toDouble();
    final createdAt = (w['created_at'] as String? ?? '').split('T').first;
    final Color statusColor;
    switch (status) {
      case 'APPROVED':
        statusColor = Colors.blue;
        break;
      case 'PROCESSED':
        statusColor = AppColors.success;
        break;
      case 'REJECTED':
        statusColor = AppColors.error;
        break;
      default:
        statusColor = AppColors.warning;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(LucideIcons.landmark, color: statusColor, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('\u20B9${amount.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                if (netAmount != null)
                  Text('Net: \u20B9${netAmount.toInt()}', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                Text(createdAt, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
            child: Text(status, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: statusColor)),
          ),
        ],
      ),
    );
  }

  void _showWithdrawDialog(BuildContext context, double maxBalance) {
    _amountController.clear();
    String? selectedBankAccountId;

    if (_bankAccounts.isNotEmpty) {
      final first = _bankAccounts.first;
      selectedBankAccountId = first['id'] as String?;
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Withdrawal Request'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Enter amount to withdraw (min \u20B9500, 2% fee applies).'),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Amount (\u20B9)',
                      prefixIcon: Icon(LucideIcons.indianRupee),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_bankAccounts.isEmpty)
                    const Text('No bank accounts found. Add one in Settings.', style: TextStyle(color: AppColors.error, fontSize: 12))
                  else
                    DropdownButtonFormField<String>(
                      value: selectedBankAccountId,
                      decoration: const InputDecoration(labelText: 'Bank Account'),
                      dropdownColor: AppColors.surface,
                      items: _bankAccounts.map((acc) {
                        final id = acc['id'] as String? ?? '';
                        final label = '${acc['bank_name'] ?? ''} - ${acc['account_number']?.toString().substring(0, 4) ?? '****'}';
                        return DropdownMenuItem(value: id, child: Text(label, style: const TextStyle(color: Colors.white)));
                      }).toList(),
                      onChanged: (val) {
                        setDialogState(() => selectedBankAccountId = val);
                      },
                    ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/vendor/bank-settings'),
                    child: const Text('Manage Bank Accounts', style: TextStyle(color: AppColors.primary, fontSize: 12)),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL', style: TextStyle(color: AppColors.textSecondary))),
                ElevatedButton(
                  onPressed: () {
                    final amt = double.tryParse(_amountController.text.trim());
                    if (amt == null || amt <= 0 || selectedBankAccountId == null) return;
                    context.read<WalletBloc>().add(RequestWithdrawal(amount: amt, bankAccountId: selectedBankAccountId!));
                    Navigator.pop(ctx);
                  },
                  child: const Text('SUBMIT'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}