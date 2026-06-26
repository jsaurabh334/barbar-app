import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_theme.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_event.dart';
import '../bloc/marketplace/marketplace_bloc.dart';
import '../bloc/marketplace/marketplace_event.dart';
import '../bloc/marketplace/marketplace_state.dart';
import '../bloc/wallet/wallet_bloc.dart';
import '../bloc/wallet/wallet_event.dart';
import '../bloc/wallet/wallet_state.dart';

class VendorDashboardScreen extends StatefulWidget {
  const VendorDashboardScreen({super.key});

  @override
  State<VendorDashboardScreen> createState() => _VendorDashboardScreenState();
}

class _VendorDashboardScreenState extends State<VendorDashboardScreen> {
  int _selectedTab = 0;
  final _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<MarketplaceBloc>().add(FetchProducts());
    context.read<MarketplaceBloc>().add(FetchAllOrders());
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
        title: const Text('VENDOR CONSOLE'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.logOut),
            onPressed: () => context.read<AuthBloc>().add(LogoutRequested()),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTab,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        backgroundColor: AppColors.surface,
        onTap: (index) {
          setState(() {
            _selectedTab = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(LucideIcons.package), label: 'Products'),
          BottomNavigationBarItem(icon: Icon(LucideIcons.truck), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(LucideIcons.wallet), label: 'Payouts'),
        ],
      ),
      body: IndexedStack(
        index: _selectedTab,
        children: [
          _buildProductsTab(),
          _buildOrdersTab(),
          _buildPayoutsTab(),
        ],
      ),
    );
  }

  Widget _buildProductsTab() {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.black,
        child: const Icon(LucideIcons.plus),
        onPressed: () => _showAddProductDialog(context),
      ),
      body: BlocBuilder<MarketplaceBloc, MarketplaceState>(
        builder: (context, state) {
          if (state is MarketplaceLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          } else if (state is ProductsLoaded) {
            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: state.products.length,
              itemBuilder: (context, index) {
                final p = state.products[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: ListTile(
                    leading: Image.network(
                      p.imageUrl ?? '',
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (c, _, __) => const Icon(LucideIcons.package),
                    ),
                    title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Stock: ${p.availableStock} remaining'),
                    trailing: Text(
                      '₹${p.basePrice.toInt()}',
                      style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primary, fontSize: 16),
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

  Widget _buildOrdersTab() {
    return BlocBuilder<MarketplaceBloc, MarketplaceState>(
      builder: (context, state) {
        if (state is MarketplaceLoading) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        } else if (state is OrdersLoaded) {
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: state.orders.length,
            itemBuilder: (context, index) {
              final o = state.orders[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(o.orderNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          o.status.toUpperCase(),
                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                    const Divider(height: 20, color: AppColors.border),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Amount Settled:', style: TextStyle(color: AppColors.textSecondary)),
                        Text('₹${o.finalAmount.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (o.status == 'confirmed')
                      ElevatedButton(
                        onPressed: () {
                          context.read<MarketplaceBloc>().add(
                            UpdateOrderStatus(orderId: o.id, status: 'processing'),
                          );
                        },
                        child: const Text('START PROCESSING'),
                      )
                    else if (o.status == 'processing')
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                        onPressed: () {
                          context.read<MarketplaceBloc>().add(
                            UpdateOrderStatus(orderId: o.id, status: 'shipped'),
                          );
                        },
                        child: const Text('SHIP PACKAGE'),
                      )
                    else
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.checkCircle, color: AppColors.success, size: 16),
                          SizedBox(width: 8),
                          Text('Package dispatched via courier', style: TextStyle(color: AppColors.success, fontSize: 12)),
                        ],
                      ),
                  ],
                ),
              );
            },
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildPayoutsTab() {
    return BlocConsumer<WalletBloc, WalletState>(
      listener: (context, state) {
        if (state is WithdrawalSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Payout withdraw of ₹${state.newBalance.toInt()} requested!'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is WalletLoaded) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildMerchantEarningsCard(state.balance),
                const SizedBox(height: 28),
                Text('Settled earnings list', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: state.transactions.length,
                  itemBuilder: (context, index) {
                    final tx = state.transactions[index];
                    return ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: AppColors.surface,
                        child: Icon(LucideIcons.arrowDownLeft, color: AppColors.success, size: 16),
                      ),
                      title: Text(tx.description),
                      subtitle: Text(tx.createdAt.split('T').first),
                      trailing: Text(
                        '₹${tx.amount.toInt()}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildMerchantEarningsCard(double balance) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('TOTAL MERCHANT REVENUE', style: TextStyle(color: AppColors.textSecondary, fontSize: 10, letterSpacing: 1.5)),
          const SizedBox(height: 8),
          Text(
            '₹${balance.toStringAsFixed(2)}',
            style: const TextStyle(color: AppColors.primary, fontSize: 32, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _showWithdrawDialog(context, balance),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.arrowUpRight, size: 16),
                SizedBox(width: 8),
                Text('REQUEST PAYOUTS'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddProductDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Register Product'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(decoration: InputDecoration(labelText: 'Product Name')),
              SizedBox(height: 12),
              TextField(decoration: InputDecoration(labelText: 'Description')),
              SizedBox(height: 12),
              TextField(decoration: InputDecoration(labelText: 'Base Price')),
              SizedBox(height: 12),
              TextField(decoration: InputDecoration(labelText: 'Initial Stock')),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Product submitted for Admin approval!'), backgroundColor: AppColors.success),
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

  void _showWithdrawDialog(BuildContext context, double maxBalance) {
    _amountController.clear();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Request Payout Transfer'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Withdrawal Payout Amount'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () {
                final amt = double.tryParse(_amountController.text.trim());
                if (amt == null || amt <= 0) return;
                
                context.read<WalletBloc>().add(
                  RequestWithdrawal(
                    amount: amt,
                    bankAccountId: 'merchant-bank-1',
                  ),
                );
                Navigator.pop(context);
              },
              child: const Text('REQUEST'),
            ),
          ],
        );
      },
    );
  }
}
