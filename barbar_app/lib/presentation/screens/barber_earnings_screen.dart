import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_theme.dart';
import '../bloc/barber_earnings/barber_earnings_bloc.dart';
import '../bloc/barber_earnings/barber_earnings_event.dart';
import '../bloc/barber_earnings/barber_earnings_state.dart';

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
      backgroundColor: const Color(0xFF0F0F15),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F15),
        elevation: 0,
        centerTitle: true,
        title: Text(
          'EARNINGS & REVENUE',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.white,
            letterSpacing: 1.0,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, color: AppColors.primary, size: 20),
            onPressed: _load,
            tooltip: 'Refresh Earnings',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: BlocConsumer<BarberEarningsBloc, BarberEarningsState>(
          listener: (context, state) {
            if (state is BarberEarningsFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.error, style: GoogleFonts.outfit(color: Colors.white)),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is BarberEarningsLoading) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primary));
            }

            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async => _load(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildPeriodSelector(),
                    const SizedBox(height: 20),
                    _buildTotalCard(state),
                    const SizedBox(height: 20),
                    _buildChartSection(state),
                    const SizedBox(height: 20),
                    _buildHistoryList(state),
                  ],
                ),
              ),
            );
          },
        ),
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
                color: isSelected ? AppColors.primary : const Color(0xFF1E1E2E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isSelected ? AppColors.primary : Colors.white12),
              ),
              child: Center(
                child: Text(
                  labels[period]!,
                  style: GoogleFonts.outfit(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.black : Colors.white70,
                    fontSize: 13,
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
    int totalCount = 0;
    if (state is BarberEarningsLoaded) {
      total = state.total;
      for (var e in state.earnings) {
        totalCount += (e['count'] as num?)?.toInt() ?? 0;
      }
    }

    final periodLabel = _selectedPeriod == 'week'
        ? 'This Week'
        : _selectedPeriod == 'month'
            ? 'This Month'
            : 'This Year';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1E2E), Color(0xFF141420)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.wallet, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                'TOTAL REVENUE',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '₹${total.toStringAsFixed(0)}',
            style: GoogleFonts.outfit(
              fontSize: 44,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Text(
              '$periodLabel • $totalCount Completed Services',
              style: GoogleFonts.outfit(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection(BarberEarningsState state) {
    List<Map<String, dynamic>> earnings = [];
    if (state is BarberEarningsLoaded) {
      earnings = state.earnings;
    }

    if (earnings.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          children: [
            const Icon(LucideIcons.barChart2, size: 40, color: Colors.white24),
            const SizedBox(height: 12),
            Text(
              'No Completed Revenue Yet',
              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 6),
            Text(
              'When you complete appointment services (click "FINISH SERVICE"), your daily earnings breakdown and graphs will appear here.',
              style: GoogleFonts.outfit(fontSize: 12, color: Colors.white54),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final maxAmount = earnings.fold<double>(0, (max, e) {
      final amt = (e['amount'] as num?)?.toDouble() ?? 0;
      return amt > max ? amt : max;
    });

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.trendingUp, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'DAILY EARNINGS BREAKDOWN',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: earnings.take(7).map((e) {
                final amt = (e['amount'] as num?)?.toDouble() ?? 0;
                final fraction = maxAmount > 0 ? amt / maxAmount : 0.0;
                final date = (e['date'] as String?)?.substring(5) ?? '';
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '₹${amt.toInt()}',
                          style: GoogleFonts.outfit(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: (fraction * 100).clamp(12.0, 100.0),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.primary, Color(0xFFFFA726)],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          date,
                          style: GoogleFonts.outfit(fontSize: 10, color: Colors.white38),
                        ),
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
        Row(
          children: [
            const Icon(LucideIcons.calendar, size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              'EARNINGS HISTORY LOG',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...earnings.map((e) {
          final date = (e['date'] as String?) ?? '';
          final amount = (e['amount'] as num?)?.toDouble() ?? 0;
          final count = (e['count'] as num?)?.toInt() ?? 0;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E2E),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(LucideIcons.banknote, color: AppColors.success, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        date,
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$count completed appointments',
                        style: GoogleFonts.outfit(fontSize: 12, color: Colors.white54),
                      ),
                    ],
                  ),
                ),
                Text(
                  '₹${amount.toInt()}',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.success, fontSize: 16),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
