import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:barbar_app/core/theme/app_theme.dart';
import 'package:barbar_app/presentation/bloc/admin/admin_wallet_bloc.dart';
import 'package:barbar_app/data/models/settlement_model.dart';
import 'package:barbar_app/presentation/widgets/admin/admin_empty_state.dart';
import 'package:barbar_app/presentation/screens/admin/finance/admin_wallet_detail_screen.dart';

class AdminWalletManagementScreen extends StatefulWidget {
  const AdminWalletManagementScreen({super.key});

  @override
  State<AdminWalletManagementScreen> createState() => _AdminWalletManagementScreenState();
}

class _AdminWalletManagementScreenState extends State<AdminWalletManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<WalletAdminModel> _allWallets = [];
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _loadTab();
      }
    });
    _loadTab();
  }

  void _loadTab() {
    setState(() {
      _allWallets.clear();
    });
    final types = ['customer', 'vendor', 'delivery'];
    context.read<AdminWalletBloc>().add(LoadAdminWallets(type: types[_tabController.index]));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallet Administration'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(icon: Icon(LucideIcons.users), text: 'Customer'),
            Tab(icon: Icon(LucideIcons.store), text: 'Vendor'),
            Tab(icon: Icon(LucideIcons.bike), text: 'Delivery'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildWalletList(),
          _buildWalletList(),
          _buildWalletList(),
        ],
      ),
    );
  }

  Widget _buildWalletList() {
    return BlocConsumer<AdminWalletBloc, AdminWalletState>(
      listener: (context, state) {
        if (state is AdminWalletLoaded && !_isLoadingMore) {
          _allWallets.clear();
          _allWallets.addAll(state.wallets);
        } else if (state is AdminWalletLoaded && _isLoadingMore) {
          _allWallets.addAll(state.wallets);
          _isLoadingMore = false;
        } else if (state is AdminWalletActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: AppColors.success));
          _loadTab();
        } else if (state is AdminWalletError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: AppColors.error));
        }
      },
      builder: (context, state) {
        if (state is AdminWalletLoading && _allWallets.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (_allWallets.isEmpty) {
          return const AdminEmptyState(title: 'No wallets found');
        }
        return RefreshIndicator(
          onRefresh: () async {
            _loadTab();
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _allWallets.length + (_isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _allWallets.length) {
                return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
              }
              return _buildWalletCard(_allWallets[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildWalletCard(WalletAdminModel wallet) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.cardBg,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: context.read<AdminWalletBloc>(),
            child: AdminWalletDetailScreen(wallet: wallet),
          ),
        )),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(wallet.ownerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: wallet.isActive ? Colors.green.withValues(alpha: 0.15) : Colors.red.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      wallet.isActive ? 'ACTIVE' : 'FROZEN',
                      style: TextStyle(
                        color: wallet.isActive ? Colors.green : Colors.red,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(LucideIcons.wallet, size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text('₹${wallet.balance.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.primary)),
                ],
              ),
              const SizedBox(height: 4),
              Text('Locked: ₹${wallet.lockedBalance.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
