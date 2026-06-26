import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_theme.dart';
import '../bloc/wallet/wallet_bloc.dart';
import '../bloc/wallet/wallet_event.dart';
import '../bloc/wallet/wallet_state.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<WalletBloc>().add(FetchWalletDetails());
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WALLET & LEDGER'),
      ),
      body: BlocConsumer<WalletBloc, WalletState>(
        listener: (context, state) {
          if (state is WithdrawalSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Withdrawal payout request submitted! Updated balance: ₹${state.newBalance.toInt()}'),
                backgroundColor: AppColors.success,
              ),
            );
          } else if (state is WalletFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is WalletLoading && state is! WalletLoaded) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          } else if (state is WalletLoaded) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Gold Premium Card Layout
                  _buildGoldBalanceCard(state.balance),
                  const SizedBox(height: 28),
                  
                  // Ledger History
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Transaction Ledger', style: Theme.of(context).textTheme.titleLarge),
                      const Icon(LucideIcons.history, color: AppColors.textSecondary, size: 20),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: state.transactions.length,
                    itemBuilder: (context, index) {
                      final tx = state.transactions[index];
                      return _buildTransactionItem(tx);
                    },
                  ),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildGoldBalanceCard(double balance) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [
            Color(0xFFE5A93C), // Champagne Gold Light
            Color(0xFF8A6E4B), // Vintage Bronze
            Color(0xFF1E1E1E), // Obsidian Dark edge
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'BARBAR PLATINUM WALLET',
                style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5),
              ),
              Icon(LucideIcons.landmark, color: Colors.white70, size: 22),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'AVAILABLE BALANCE',
            style: TextStyle(color: Colors.white60, fontSize: 11, letterSpacing: 1),
          ),
          const SizedBox(height: 4),
          Text(
            '₹${balance.toStringAsFixed(2)}',
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -0.5),
          ),
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
                Text('REQUEST BANK WITHDRAWAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
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
          child: Icon(
            isCredit ? LucideIcons.arrowDownLeft : LucideIcons.arrowUpRight,
            color: isCredit ? AppColors.success : AppColors.error,
            size: 18,
          ),
        ),
        title: Text(tx.description, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        subtitle: Text(
          tx.createdAt.split('T').first,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${isCredit ? "+" : "-"}₹${tx.amount.toInt()}',
              style: TextStyle(
                color: isCredit ? AppColors.success : AppColors.error,
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              tx.status.toUpperCase(),
              style: TextStyle(
                color: tx.status == 'settled' ? AppColors.textMuted : AppColors.warning,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showWithdrawDialog(BuildContext context, double maxBalance) {
    _amountController.clear();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Bank Payout Request'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Enter withdrawal amount. settled payout fees (2%) apply.'),
              const SizedBox(height: 16),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount (INR)',
                  prefixIcon: Icon(LucideIcons.indianRupee),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                final amt = double.tryParse(_amountController.text.trim());
                if (amt == null || amt <= 0) return;
                
                context.read<WalletBloc>().add(
                  RequestWithdrawal(
                    amount: amt,
                    bankAccountId: 'bank-acc-uuid-1',
                  ),
                );
                Navigator.pop(context);
              },
              child: const Text('SUBMIT'),
            ),
          ],
        );
      },
    );
  }
}
