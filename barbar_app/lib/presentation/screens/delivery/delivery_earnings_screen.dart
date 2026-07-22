import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../bloc/delivery/delivery_bloc.dart';
import '../../bloc/delivery/delivery_event.dart';
import '../../bloc/delivery/delivery_state.dart';

class DeliveryEarningsScreen extends StatefulWidget {
  const DeliveryEarningsScreen({super.key});

  @override
  State<DeliveryEarningsScreen> createState() => _DeliveryEarningsScreenState();
}

class _DeliveryEarningsScreenState extends State<DeliveryEarningsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<DeliveryBloc>().add(FetchEarningSummary());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Earnings'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw),
            onPressed: () => context.read<DeliveryBloc>().add(FetchEarningSummary()),
          ),
        ],
      ),
      body: BlocBuilder<DeliveryBloc, DeliveryState>(
        builder: (context, state) {
          if (state is DeliveryLoading && state is! DeliveryEarningsLoaded) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          if (state is DeliveryFailure) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(state.error, style: const TextStyle(color: AppColors.error), textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<DeliveryBloc>().add(FetchEarningSummary()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final earnings = state is DeliveryEarningsLoaded ? state.earnings : <Map<String, dynamic>>[];
          final summary = state is DeliveryEarningsLoaded ? state.summary : null;

          return RefreshIndicator(
            onRefresh: () async {
              context.read<DeliveryBloc>().add(FetchEarningSummary());
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSummaryCards(summary),
                  const SizedBox(height: 24),
                  const Text('Earning History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 12),
                  ...earnings.map((e) => _buildEarningTile(e)),
                  if (earnings.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('No earnings yet', style: TextStyle(color: AppColors.textSecondary), textAlign: TextAlign.center),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCards(Map<String, dynamic>? summary) {
    final f = NumberFormat.currency(symbol: '\u20b9', decimalDigits: 0);
    return Column(
      children: [
        Row(
          children: [
            _summaryCard('Total Earnings', f.format(summary?['total_earnings'] ?? 0), LucideIcons.wallet, AppColors.primary),
            const SizedBox(width: 12),
            _summaryCard('This Month', f.format(summary?['this_month'] ?? 0), LucideIcons.calendar, AppColors.success),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _summaryCard('This Week', f.format(summary?['this_week'] ?? 0), LucideIcons.trendingUp, AppColors.info),
            const SizedBox(width: 12),
            _summaryCard('Pending', f.format(summary?['pending_amount'] ?? 0), LucideIcons.clock, AppColors.warning),
          ],
        ),
      ],
    );
  }

  Widget _summaryCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 12),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningTile(Map<String, dynamic> earning) {
    final f = NumberFormat.currency(symbol: '\u20b9', decimalDigits: 0);
    final date = earning['created_at'] != null ? DateTime.tryParse(earning['created_at']) : null;
    final status = earning['status'] ?? 'pending';
    final isSettled = status == 'settled';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
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
              color: (isSettled ? AppColors.success : AppColors.warning).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isSettled ? LucideIcons.checkCircle : LucideIcons.clock,
              color: isSettled ? AppColors.success : AppColors.warning,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Order #${earning['reference_id'] ?? earning['order_id']?.toString().substring(0, 8) ?? ''}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                if (date != null)
                  Text(DateFormat('MMM dd, yyyy').format(date), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(f.format(earning['total_amount'] ?? 0), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              Text(status.toUpperCase(), style: TextStyle(fontSize: 11, color: isSettled ? AppColors.success : AppColors.warning)),
            ],
          ),
        ],
      ),
    );
  }
}
