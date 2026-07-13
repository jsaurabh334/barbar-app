import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_theme.dart';
import '../bloc/barber_earnings/barber_earnings_bloc.dart';
import '../bloc/barber_earnings/barber_earnings_event.dart';
import '../bloc/barber_earnings/barber_earnings_state.dart';
import '../widgets/glass_card.dart';

class BarberEarningsScreen extends StatefulWidget {
  const BarberEarningsScreen({super.key});

  @override
  State<BarberEarningsScreen> createState() => _BarberEarningsScreenState();
}

class _BarberEarningsScreenState extends State<BarberEarningsScreen> {
  String _selectedPeriod = 'week';

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    context.read<BarberEarningsBloc>().add(FetchEarnings(period: _selectedPeriod));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('EARNINGS')),
      body: BlocConsumer<BarberEarningsBloc, BarberEarningsState>(
        listener: (context, state) {
          if (state is BarberEarningsFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error), backgroundColor: AppColors.error),
            );
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildPeriodSelector(),
                const SizedBox(height: 24),
                _buildTotalCard(state),
                const SizedBox(height: 24),
                _buildChartPlaceholder(state),
                const SizedBox(height: 24),
                _buildHistoryList(state),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Row(
      children: ['week', 'month', 'year'].map((period) {
        final labels = {'week': 'Weekly', 'month': 'Monthly', 'year': 'Yearly'};
        final isSelected = _selectedPeriod == period;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() => _selectedPeriod = period);
              _load();
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
              ),
              child: Center(
                child: Text(
                  labels[period]!,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.black : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTotalCard(BarberEarningsState state) {
    double total = 0;
    if (state is BarberEarningsLoaded) {
      total = state.total;
    }

    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text(
            'TOTAL EARNINGS',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1.5),
          ),
          const SizedBox(height: 12),
          Text(
            '₹${total.toStringAsFixed(0)}',
            style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: AppColors.primary),
          ),
          const SizedBox(height: 4),
          Text(
            _selectedPeriod == 'week' ? 'This Week' : _selectedPeriod == 'month' ? 'This Month' : 'This Year',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildChartPlaceholder(BarberEarningsState state) {
    List<Map<String, dynamic>> earnings = [];
    if (state is BarberEarningsLoaded) {
      earnings = state.earnings;
    }

    if (earnings.isEmpty) {
      return const SizedBox.shrink();
    }

    final maxAmount = earnings.fold<double>(0, (max, e) {
      final amt = (e['amount'] as num?)?.toDouble() ?? 0;
      return amt > max ? amt : max;
    });

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('DAILY BREAKDOWN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: earnings.take(7).map((e) {
                final amt = (e['amount'] as num?)?.toDouble() ?? 0;
                final fraction = maxAmount > 0 ? amt / maxAmount : 0.0;
                final date = (e['date'] as String?)?.substring(5) ?? '';
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('₹${amt.toInt()}', style: const TextStyle(fontSize: 8, color: AppColors.textSecondary)),
                        const SizedBox(height: 4),
                        Container(
                          height: (fraction * 100).clamp(8.0, 100.0),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(date, style: const TextStyle(fontSize: 8, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList(BarberEarningsState state) {
    List<Map<String, dynamic>> earnings = [];
    if (state is BarberEarningsLoaded) {
      earnings = state.earnings;
    }

    if (earnings.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('EARNINGS HISTORY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
        const SizedBox(height: 12),
        ...earnings.map((e) {
          final date = (e['date'] as String?) ?? '';
          final amount = (e['amount'] as num?)?.toDouble() ?? 0;
          final count = (e['count'] as num?)?.toInt() ?? 0;
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
                const Icon(LucideIcons.banknote, color: AppColors.primary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(date, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('$count bookings', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Text('₹${amount.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.success, fontSize: 16)),
              ],
            ),
          );
        }),
      ],
    );
  }
}
