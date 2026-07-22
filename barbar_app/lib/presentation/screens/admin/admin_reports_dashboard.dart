import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:barbar_app/core/theme/app_theme.dart';
import 'package:barbar_app/presentation/bloc/admin/admin_reports_bloc.dart';
import 'package:barbar_app/data/models/analytics_dashboard_model.dart';
import 'package:barbar_app/presentation/widgets/admin/analytics/admin_metric_card.dart';
import 'package:barbar_app/presentation/widgets/admin/analytics/admin_chart_card.dart';
import 'package:barbar_app/presentation/widgets/admin/analytics/admin_analytics_filter_bar.dart';
import 'package:barbar_app/presentation/widgets/admin/analytics/admin_analytics_section.dart';
import 'package:barbar_app/presentation/widgets/admin/analytics/admin_analytics_empty_state.dart';


class AdminReportsDashboard extends StatefulWidget {
  const AdminReportsDashboard({super.key});

  @override
  State<AdminReportsDashboard> createState() => _AdminReportsDashboardState();
}

class _AdminReportsDashboardState extends State<AdminReportsDashboard> {
  String _period = 'month';

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  void _loadAll() {
    final bloc = context.read<AdminReportsBloc>();
    bloc.add(LoadRevenueReport(period: _period));
    bloc.add(LoadBookingAnalytics(period: _period));
    bloc.add(LoadOrderAnalytics(period: _period));
    bloc.add(LoadCustomerAnalytics(period: _period));
    bloc.add(const LoadDeliveryAnalytics());
    bloc.add(const LoadBarberAnalytics());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: AdminAnalyticsFilterBar(
            selectedPeriod: _period,
            onPeriodChanged: (p) {
              setState(() => _period = p);
              _loadAll();
            },
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildRevenueSection(),
            _buildBookingSection(),
            _buildOrderSection(),
            _buildCustomerSection(),
            _buildBarberSection(),
            _buildDeliverySection(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueSection() {
    return BlocBuilder<AdminReportsBloc, AdminReportsState>(
      buildWhen: (prev, cur) => cur is AdminRevenueReportLoaded || cur is AdminReportsLoading || cur is AdminReportsError,
      builder: (context, state) {
        if (state is AdminRevenueReportLoaded) return _buildRevenueContent(state.data);
        if (state is AdminReportsError) return _buildErrorSection('Revenue');
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildRevenueContent(RevenueAnalytics data) {
    final isEmpty = data.records.isEmpty;
    return AdminAnalyticsSection(
      title: 'Revenue',
      subtitle: '${_period == 'week' ? '7-day' : _period == 'year' ? '12-month' : '30-day'} performance',
      child: Column(
        children: [
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: AdminMetricCard(label: 'Total Revenue', value: '₹${_fmt(data.totalRevenue)}', icon: LucideIcons.trendingUp, color: AppColors.primary)),
              const SizedBox(width: 12),
              Expanded(child: AdminMetricCard(label: 'Commission', value: '₹${_fmt(data.totalCommission)}', icon: LucideIcons.coins, color: Colors.amber)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: AdminMetricCard(label: 'Orders', value: '${data.totalOrders}', icon: LucideIcons.shoppingCart, color: Colors.blue)),
              const SizedBox(width: 12),
              Expanded(child: AdminMetricCard(label: 'Avg Order', value: '₹${_fmt(data.avgOrderValue)}', icon: LucideIcons.receipt, color: Colors.teal)),
            ],
          ),
          const SizedBox(height: 16),
          if (isEmpty)
            const AdminChartCard(title: 'Trend', height: 160, child: AdminAnalyticsEmptyState())
          else
            AdminChartCard(
              title: 'Daily Revenue Trend',
              height: 200,
              child: _RevenueLineChart(records: data.records),
            ),
        ],
      ),
    );
  }

  Widget _buildBookingSection() {
    return BlocBuilder<AdminReportsBloc, AdminReportsState>(
      buildWhen: (prev, cur) => cur is AdminBookingAnalyticsLoaded || cur is AdminReportsLoading,
      builder: (context, state) {
        if (state is AdminBookingAnalyticsLoaded) return _buildBookingContent(state.data);
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildBookingContent(BookingAnalytics data) {
    return AdminAnalyticsSection(
      title: 'Bookings',
      subtitle: '${data.totalBookings} total, ${data.completed} completed',
      child: Column(
        children: [
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: AdminMetricCard(label: 'Total', value: '${data.totalBookings}', icon: LucideIcons.calendarCheck, color: Colors.blue)),
              const SizedBox(width: 12),
              Expanded(child: AdminMetricCard(label: 'Completed', value: '${data.completed}', icon: LucideIcons.checkCircle, color: Colors.green, trend: data.totalBookings > 0 ? '${(data.completed * 100 ~/ data.totalBookings)}%' : null)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: AdminMetricCard(label: 'Cancelled', value: '${data.cancelled}', icon: LucideIcons.xCircle, color: AppColors.error)),
              const SizedBox(width: 12),
              Expanded(child: AdminMetricCard(label: 'Revenue', value: '₹${_fmt(data.totalRevenue)}', icon: LucideIcons.trendingUp, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 16),
          if (data.records.isNotEmpty)
            AdminChartCard(
              title: 'Daily Booking Trend',
              height: 200,
              child: _BookingBarChart(records: data.records),
            ),
        ],
      ),
    );
  }

  Widget _buildOrderSection() {
    return BlocBuilder<AdminReportsBloc, AdminReportsState>(
      buildWhen: (prev, cur) => cur is AdminOrderAnalyticsLoaded || cur is AdminReportsLoading,
      builder: (context, state) {
        if (state is AdminOrderAnalyticsLoaded) return _buildOrderContent(state.data);
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildOrderContent(OrderAnalytics data) {
    return AdminAnalyticsSection(
      title: 'Orders',
      subtitle: '${data.totalOrders} total, ${data.delivered} delivered',
      child: Column(
        children: [
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: AdminMetricCard(label: 'Total Orders', value: '${data.totalOrders}', icon: LucideIcons.shoppingCart, color: Colors.blue)),
              const SizedBox(width: 12),
              Expanded(child: AdminMetricCard(label: 'Delivered', value: '${data.delivered}', icon: LucideIcons.checkCircle, color: Colors.green)),
            ],
          ),
          const SizedBox(height: 16),
          if (data.records.isNotEmpty)
            AdminChartCard(
              title: 'Daily Order Trend',
              height: 200,
              child: _OrderLineChart(records: data.records),
            ),
        ],
      ),
    );
  }

  Widget _buildCustomerSection() {
    return BlocBuilder<AdminReportsBloc, AdminReportsState>(
      buildWhen: (prev, cur) => cur is AdminCustomerAnalyticsLoaded || cur is AdminReportsLoading,
      builder: (context, state) {
        if (state is AdminCustomerAnalyticsLoaded) return _buildCustomerContent(state.data);
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildCustomerContent(CustomerAnalytics data) {
    return AdminAnalyticsSection(
      title: 'Customer Growth',
      subtitle: '${data.totalCustomers} total, ${data.newCustomers} new',
      child: Column(
        children: [
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: AdminMetricCard(label: 'Total Customers', value: '${data.totalCustomers}', icon: LucideIcons.users, color: Colors.purple)),
              const SizedBox(width: 12),
              Expanded(child: AdminMetricCard(label: 'New ($_period)', value: '${data.newCustomers}', icon: LucideIcons.userPlus, color: Colors.indigo)),
            ],
          ),
          const SizedBox(height: 16),
          if (data.records.isNotEmpty)
            AdminChartCard(
              title: 'Customer Registrations',
              height: 160,
              child: _CustomerLineChart(records: data.records),
            ),
        ],
      ),
    );
  }

  Widget _buildBarberSection() {
    return BlocBuilder<AdminReportsBloc, AdminReportsState>(
      buildWhen: (prev, cur) => cur is AdminBarberAnalyticsLoaded || cur is AdminReportsLoading,
      builder: (context, state) {
        if (state is AdminBarberAnalyticsLoaded) return _buildBarberContent(state.data);
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildBarberContent(BarberAnalytics data) {
    return AdminAnalyticsSection(
      title: 'Barbers',
      subtitle: '${data.approved} active of ${data.totalBarbers} total',
      child: Column(
        children: [
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: AdminMetricCard(label: 'Total', value: '${data.totalBarbers}', icon: LucideIcons.scissors, color: Colors.blue)),
              const SizedBox(width: 12),
              Expanded(child: AdminMetricCard(label: 'Approved', value: '${data.approved}', icon: LucideIcons.checkCircle, color: Colors.green)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: AdminMetricCard(label: 'Pending', value: '${data.pending}', icon: LucideIcons.clock, color: Colors.orange)),
              const SizedBox(width: 12),
              Expanded(child: AdminMetricCard(label: 'Avg Rating', value: data.avgRating.toStringAsFixed(1), icon: LucideIcons.star, color: Colors.amber)),
            ],
          ),
          const SizedBox(height: 12),
          if (data.topBarbers.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Top Barbers', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 12),
                  ...data.topBarbers.take(5).map((b) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.scissors, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Expanded(child: Text(b.shopName, style: const TextStyle(fontSize: 13))),
                        Text('₹${_fmt(b.revenue)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDeliverySection() {
    return BlocBuilder<AdminReportsBloc, AdminReportsState>(
      buildWhen: (prev, cur) => cur is AdminDeliveryAnalyticsLoaded || cur is AdminReportsLoading,
      builder: (context, state) {
        if (state is AdminDeliveryAnalyticsLoaded) return _buildDeliveryContent(state.data);
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildDeliveryContent(DeliveryAnalytics data) {
    return AdminAnalyticsSection(
      title: 'Delivery',
      subtitle: '${data.online} online of ${data.totalPartners} total',
      child: Column(
        children: [
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: AdminMetricCard(label: 'Total Partners', value: '${data.totalPartners}', icon: LucideIcons.bike, color: Colors.blue)),
              const SizedBox(width: 12),
              Expanded(child: AdminMetricCard(label: 'Online', value: '${data.online}', icon: LucideIcons.wifi, color: Colors.green)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: AdminMetricCard(label: 'Busy', value: '${data.busy}', icon: LucideIcons.briefcase, color: Colors.orange)),
              const SizedBox(width: 12),
              Expanded(child: AdminMetricCard(label: 'Deliveries', value: '${data.totalDeliveries}', icon: LucideIcons.package, color: AppColors.primary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorSection(String label) {
    return AdminAnalyticsSection(
      title: label,
      child: const Padding(
        padding: EdgeInsets.all(20),
        child: AdminAnalyticsEmptyState(message: 'Could not load data'),
      ),
    );
  }

  String _fmt(num value) {
    if (value >= 100000) return '${(value / 100000).toStringAsFixed(1)}L';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toStringAsFixed(value == value.roundToDouble() ? 0 : 1);
  }
}

class _RevenueLineChart extends StatelessWidget {
  final List<RevenueRecord> records;
  const _RevenueLineChart({required this.records});

  @override
  Widget build(BuildContext context) {
    final spots = records.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.totalRevenue)).toList();
    final maxY = spots.isEmpty ? 1.0 : spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 16, top: 8, bottom: 8),
      child: LineChart(LineChartData(
        gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: maxY / 4),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 24,
            interval: (spots.length / 5).ceilToDouble().clamp(1, double.infinity),
            getTitlesWidget: (v, _) {
              final i = v.toInt();
              if (i < 0 || i >= records.length) return const SizedBox.shrink();
              final date = records[i].date;
              return Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(date.length >= 5 ? date.substring(date.length - 5) : date, style: const TextStyle(fontSize: 9)),
              );
            },
          )),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(spots: spots, isCurved: true, color: Colors.teal, barWidth: 2.5, dotData: const FlDotData(show: false)),
        ],
      )),
    );
  }
}

class _BookingBarChart extends StatelessWidget {
  final List<BookingTrend> records;
  const _BookingBarChart({required this.records});

  @override
  Widget build(BuildContext context) {
    final maxY = records.isEmpty ? 1.0 : records.map((r) => r.total.toDouble()).reduce((a, b) => a > b ? a : b);
    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 16, top: 8, bottom: 8),
      child: BarChart(BarChartData(
        gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: maxY / 4),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true, reservedSize: 24,
            interval: (records.length / 5).ceilToDouble().clamp(1, double.infinity),
            getTitlesWidget: (v, _) {
              final i = v.toInt();
              if (i < 0 || i >= records.length) return const SizedBox.shrink();
              final date = records[i].date;
              return Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(date.length >= 5 ? date.substring(date.length - 5) : date, style: const TextStyle(fontSize: 9)),
              );
            },
          )),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: records.asMap().entries.map((e) => BarChartGroupData(x: e.key, barRods: [
          BarChartRodData(toY: e.value.total.toDouble(), color: AppColors.primary, width: 8, borderRadius: const BorderRadius.only(topLeft: Radius.circular(3), topRight: Radius.circular(3))),
        ])).toList(),
      )),
    );
  }
}

class _OrderLineChart extends StatelessWidget {
  final List<OrderTrend> records;
  const _OrderLineChart({required this.records});

  @override
  Widget build(BuildContext context) {
    final spots = records.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.revenue)).toList();
    final maxY = spots.isEmpty ? 1.0 : spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 16, top: 8, bottom: 8),
      child: LineChart(LineChartData(
        gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: maxY / 4),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true, reservedSize: 24,
            interval: (spots.length / 5).ceilToDouble().clamp(1, double.infinity),
            getTitlesWidget: (v, _) {
              final i = v.toInt();
              if (i < 0 || i >= records.length) return const SizedBox.shrink();
              final date = records[i].date;
              return Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(date.length >= 5 ? date.substring(date.length - 5) : date, style: const TextStyle(fontSize: 9)),
              );
            },
          )),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(spots: spots, isCurved: true, color: Colors.teal, barWidth: 2.5, dotData: const FlDotData(show: false)),
        ],
      )),
    );
  }
}

class _CustomerLineChart extends StatelessWidget {
  final List<CustomerTrend> records;
  const _CustomerLineChart({required this.records});

  @override
  Widget build(BuildContext context) {
    final spots = records.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.newUsers.toDouble())).toList();
    final maxY = spots.isEmpty ? 1.0 : spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 16, top: 8, bottom: 8),
      child: LineChart(LineChartData(
        gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: (maxY / 4).clamp(1, double.infinity)),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true, reservedSize: 24,
            interval: (spots.length / 5).ceilToDouble().clamp(1, double.infinity),
            getTitlesWidget: (v, _) {
              final i = v.toInt();
              if (i < 0 || i >= records.length) return const SizedBox.shrink();
              final date = records[i].date;
              return Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(date.length >= 5 ? date.substring(date.length - 5) : date, style: const TextStyle(fontSize: 9)),
              );
            },
          )),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(spots: spots, isCurved: true, color: Colors.purple, barWidth: 2.5, dotData: const FlDotData(show: false)),
        ],
      )),
    );
  }
}
