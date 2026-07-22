import 'package:barbar_app/presentation/bloc/admin/admin_finance_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AdminRevenueAnalyticsScreen extends StatefulWidget {
  const AdminRevenueAnalyticsScreen({super.key});
  @override
  State<AdminRevenueAnalyticsScreen> createState() => _AdminRevenueAnalyticsScreenState();
}

class _AdminRevenueAnalyticsScreenState extends State<AdminRevenueAnalyticsScreen> {
  String _period = 'month';

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    context.read<AdminFinanceBloc>().add(LoadRevenueAnalytics(period: _period));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminFinanceBloc, AdminFinanceState>(
      builder: (context, state) {
        if (state is AdminFinanceLoading) return const Center(child: CircularProgressIndicator());
        if (state is RevenueAnalyticsLoaded) {
          final data = state.data;
          final records = (data['records'] as List<dynamic>?) ?? [];
          final totals = data['totals'] as Map<String, dynamic>? ?? {};
          final totalRevenue = (totals['total_revenue'] as num?)?.toDouble() ?? 0.0;
          final totalCommission = (totals['total_commission'] as num?)?.toDouble() ?? 0.0;
          final totalOrders = (totals['total_orders'] as num?)?.toInt() ?? 0;
          final totalBookings = (totals['total_bookings'] as num?)?.toInt() ?? 0;
          final avgOrderValue = (totals['avg_order_value'] as num?)?.toDouble() ?? 0.0;

          return RefreshIndicator(
            onRefresh: () async => _load(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _periodChip('Week', 'week'),
                      const SizedBox(width: 8),
                      _periodChip('Month', 'month'),
                      const SizedBox(width: 8),
                      _periodChip('Year', 'year'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _statCard('Total Revenue', '₹${_fmt(totalRevenue)}', Colors.green),
                      const SizedBox(width: 8),
                      _statCard('Commission', '₹${_fmt(totalCommission)}', Colors.blue),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _statCard('Orders', '$totalOrders', Colors.orange),
                      const SizedBox(width: 8),
                      _statCard('Bookings', '$totalBookings', Colors.purple),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _statCard('Avg Order Value', '₹${_fmt(avgOrderValue)}', Colors.teal),
                  const SizedBox(height: 16),
                  Text('Revenue Trend ($_period)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  if (records.isEmpty)
                    const Card(child: Padding(padding: EdgeInsets.all(24), child: Center(child: Text('No data for this period', style: TextStyle(color: Colors.grey)))))
                  else
                    ...records.map((r) {
                      final date = r['date'] as String? ?? '';
                      final rev = (r['total_revenue'] as num?)?.toDouble() ?? 0.0;
                      final bookingRev = (r['booking_revenue'] as num?)?.toDouble() ?? 0.0;
                      final orderRev = (r['order_revenue'] as num?)?.toDouble() ?? 0.0;
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 3),
                        child: ListTile(
                          dense: true,
                          title: Text(date, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          subtitle: Text('Bookings: ₹${_fmt(bookingRev)}  Orders: ₹${_fmt(orderRev)}', style: const TextStyle(fontSize: 11)),
                          trailing: Text('₹${_fmt(rev)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                        ),
                      );
                    }),
                ],
              ),
            ),
          );
        }
        if (state is AdminFinanceError) return Center(child: Text('Error: ${state.message}'));
        return const SizedBox.shrink();
      },
    );
  }

  Widget _periodChip(String label, String period) {
    final sel = _period == period;
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: sel,
      onSelected: (_) { setState(() => _period = period); _load(); },
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              const SizedBox(height: 4),
              Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ),
      ),
    );
  }

  String _fmt(double n) => n >= 100000 ? '${(n / 100000).toStringAsFixed(1)}L' : n.toStringAsFixed(0);
}
