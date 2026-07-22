import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:barbar_app/core/theme/app_theme.dart';
import 'package:barbar_app/presentation/bloc/admin/admin_settlements_bloc.dart';
import 'package:barbar_app/data/models/settlement_model.dart';
import 'package:barbar_app/presentation/widgets/admin/admin_status_badge.dart';
import 'package:barbar_app/presentation/widgets/admin/admin_empty_state.dart';
import 'package:barbar_app/presentation/screens/admin/finance/admin_settlement_detail_screen.dart';

class AdminSettlementsScreen extends StatefulWidget {
  const AdminSettlementsScreen({super.key});

  @override
  State<AdminSettlementsScreen> createState() => _AdminSettlementsScreenState();
}

class _AdminSettlementsScreenState extends State<AdminSettlementsScreen> with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  String _statusFilter = '';
  int _currentPage = 1;
  bool _isLoadingMore = false;
  final List<SettlementModel> _allSettlements = [];

  @override
  void initState() {
    super.initState();
    context.read<AdminSettlementsBloc>().add(const LoadSettlements());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settlements'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.fileSpreadsheet),
            onPressed: () => _showBulkProcessDialog(),
            tooltip: 'Bulk Process',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(child: _buildSettlementList()),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['', 'pending', 'approved', 'rejected', 'processed'];
    final labels = ['All', 'Pending', 'Approved', 'Rejected', 'Processed'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(filters.length, (i) {
            final isSelected = _statusFilter == filters[i];
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(labels[i]),
                selected: isSelected,
                onSelected: (_) {
                  setState(() {
                    _statusFilter = filters[i];
                    _currentPage = 1;
                    _allSettlements.clear();
                  });
                  context.read<AdminSettlementsBloc>().add(LoadSettlements(status: filters[i].isEmpty ? null : filters[i]));
                },
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildSettlementList() {
    return BlocConsumer<AdminSettlementsBloc, AdminSettlementsState>(
      listener: (context, state) {
        if (state is AdminSettlementsLoaded && !_isLoadingMore) {
          _allSettlements.clear();
          _allSettlements.addAll(state.settlements);
        } else if (state is AdminSettlementsLoaded && _isLoadingMore) {
          _allSettlements.addAll(state.settlements);
          _isLoadingMore = false;
        } else if (state is AdminSettlementActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: AppColors.success));
          _allSettlements.clear();
          _currentPage = 1;
          context.read<AdminSettlementsBloc>().add(LoadSettlements(status: _statusFilter.isEmpty ? null : _statusFilter));
        } else if (state is AdminSettlementsError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: AppColors.error));
        }
      },
      builder: (context, state) {
        if (state is AdminSettlementsLoading && _allSettlements.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (_allSettlements.isEmpty) {
          return const AdminEmptyState(title: 'No settlements found');
        }
        return NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is ScrollEndNotification && !_isLoadingMore) {
              final maxScroll = notification.metrics.maxScrollExtent;
              final currentScroll = notification.metrics.pixels;
              if (currentScroll >= maxScroll - 200) {
                final blocState = context.read<AdminSettlementsBloc>().state;
                if (blocState is AdminSettlementsLoaded && !blocState.hasReachedMax) {
                  _isLoadingMore = true;
                  _currentPage++;
                  context.read<AdminSettlementsBloc>().add(LoadSettlements(
                    page: _currentPage,
                    isLoadMore: true,
                    status: _statusFilter.isEmpty ? null : _statusFilter,
                  ));
                }
              }
            }
            return false;
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _allSettlements.length + (_isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _allSettlements.length) {
                return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
              }
              return _buildSettlementCard(_allSettlements[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildSettlementCard(SettlementModel settlement) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.cardBg,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: context.read<AdminSettlementsBloc>(),
            child: AdminSettlementDetailScreen(settlement: settlement),
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
                    child: Text(settlement.businessName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  AdminStatusBadge(label: settlement.status),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Amount: ', style: TextStyle(color: AppColors.textSecondary)),
                  Text('₹${settlement.amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 16),
                  const Text('Net: ', style: TextStyle(color: AppColors.textSecondary)),
                  Text('₹${settlement.netAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.success)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Text('Fee: ', style: TextStyle(color: AppColors.textSecondary)),
                  Text('₹${settlement.feeAmount.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.error)),
                  const Spacer(),
                  Text(_formatDate(settlement.createdAt), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) => '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';

  void _showBulkProcessDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Bulk Process Settlements'),
        content: const Text('Select all pending settlements and approve or reject in bulk.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              final pendingIds = _allSettlements.where((s) => s.status == 'pending').map((s) => s.id).toList();
              if (pendingIds.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No pending settlements to process')));
                return;
              }
              context.read<AdminSettlementsBloc>().add(BulkProcessSettlements(ids: pendingIds, status: 'approved'));
            },
            child: const Text('Approve All Pending'),
          ),
        ],
      ),
    );
  }
}
