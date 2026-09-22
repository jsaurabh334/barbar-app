import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:barbar_app/presentation/bloc/admin/admin_dashboard_bloc.dart';
import 'package:barbar_app/domain/repositories/admin_repository.dart';
import 'package:barbar_app/presentation/screens/admin/pending_barbers_screen.dart';
import 'package:barbar_app/presentation/screens/admin/active_barbers_screen.dart';
import 'package:barbar_app/presentation/screens/admin/customers/admin_customers_screen.dart';
import 'package:barbar_app/presentation/bloc/admin/admin_customers_bloc.dart';
import 'package:barbar_app/presentation/screens/admin/vendors/admin_vendors_screen.dart';
import 'package:barbar_app/presentation/bloc/admin/admin_vendors_bloc.dart';
import 'package:barbar_app/presentation/screens/admin/admin_report_management_screen.dart';
import 'package:barbar_app/presentation/screens/admin/admin_revenue_analytics_screen.dart';
import 'package:barbar_app/presentation/screens/admin/admin_tax_settings_screen.dart';
import 'package:barbar_app/core/theme/app_theme.dart';
import 'package:barbar_app/presentation/bloc/admin/admin_barbers_bloc.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AdminDashboardBloc(
        adminRepository: context.read<AdminRepository>(),
      )..add(LoadDashboardData()),
      child: const _DashboardView(),
    );
  }
}

class _DashboardView extends StatefulWidget {
  const _DashboardView({Key? key}) : super(key: key);

  @override
  State<_DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<_DashboardView> {
  Map<String, dynamic>? _healthData;
  List<dynamic> _activityLogs = [];
  bool _loadingHealth = true;
  bool _loadingLogs = true;

  @override
  void initState() {
    super.initState();
    _fetchLiveMetrics();
  }

  Future<void> _fetchLiveMetrics() async {
    final repo = context.read<AdminRepository>();
    try {
      final healthRes = await repo.getSystemHealth();
      if (mounted) {
        setState(() {
          _healthData = healthRes['data'] as Map<String, dynamic>?;
          _loadingHealth = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingHealth = false);
    }

    try {
      final logsRes = await repo.getAuditLogs(limit: 10);
      if (mounted) {
        final raw = logsRes['data'];
        final List<dynamic> items = raw is List ? raw : (raw is Map ? (raw['items'] ?? []) : []);
        setState(() {
          _activityLogs = items;
          _loadingLogs = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingLogs = false);
    }
  }

  String _formatRealTime(DateTime? dateTime) {
    if (dateTime == null) return 'Just now';
    final localTime = dateTime.toLocal();
    final now = DateTime.now();
    final diff = now.difference(localTime);

    if (diff.inSeconds < 45 || diff.isNegative) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return DateFormat('hh:mm a').format(localTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    final todayStr = DateFormat('dd MMMM yyyy').format(DateTime.now());

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () async {
          context.read<AdminDashboardBloc>().add(LoadDashboardData());
          await _fetchLiveMetrics();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Header ---
              Text("Good Morning, Admin 👋", style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(todayStr, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 20),

              // --- Main Content ---
              BlocBuilder<AdminDashboardBloc, AdminDashboardState>(
                builder: (context, state) {
                  if (state is AdminDashboardLoading) {
                    return const SizedBox(height: 300, child: Center(child: CircularProgressIndicator(color: AppColors.primary)));
                  }
                  if (state is AdminDashboardError) {
                    return Center(child: Text("Error: ${state.message}", style: const TextStyle(color: AppColors.error)));
                  }
                  if (state is AdminDashboardLoaded) {
                    final stats = state.stats;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- Quick Stats Grid ---
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.4,
                          children: [
                            _buildStatCard(
                              context,
                              title: "Pending Approvals",
                              value: stats.pendingBarbers.toString(),
                              icon: Icons.hourglass_top,
                              color: Colors.orange,
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BlocProvider(create: (context) => AdminBarbersBloc(adminRepository: context.read<AdminRepository>()), child: const PendingBarbersScreen()))),
                            ),
                            _buildStatCard(
                              context,
                              title: "Active Barbers",
                              value: stats.approvedBarbers.toString(),
                              icon: Icons.content_cut,
                              color: Colors.green,
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BlocProvider(create: (context) => AdminBarbersBloc(adminRepository: context.read<AdminRepository>()), child: const ActiveBarbersScreen()))),
                            ),
                            _buildStatCard(context, title: "Customers", value: stats.totalCustomers.toString(), icon: Icons.people_outline, color: Colors.blue),
                            _buildStatCard(context, title: "Today's Bookings", value: stats.todayBookings.toString(), icon: Icons.calendar_today, color: Colors.purple),
                            _buildStatCard(context, title: "Today's Revenue", value: "₹${stats.todayRevenue.toStringAsFixed(0)}", icon: Icons.currency_rupee, color: Colors.indigo),
                            _buildStatCard(context, title: "Live Queue", value: stats.liveQueue.toString(), icon: Icons.queue, color: Colors.teal),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // --- Live Activity Feed ---
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Live Activity Feed", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                            if (_loadingLogs) const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Card(
                          color: AppColors.cardBg,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.border)),
                          child: _activityLogs.isEmpty
                              ? const Padding(
                                  padding: EdgeInsets.all(24),
                                  child: Center(child: Text("No activity recorded yet", style: TextStyle(color: AppColors.textSecondary))),
                                )
                              : Column(
                                  children: _activityLogs.take(5).map((log) {
                                    final title = (log['title'] as String?) ?? (log['action'] as String?) ?? 'System Action';
                                    final desc = (log['description'] as String?) ?? (log['entity_type'] as String?) ?? '';
                                    final createdAt = log['created_at'] != null ? DateTime.tryParse(log['created_at'].toString()) : null;
                                    final timeStr = _formatRealTime(createdAt);

                                    IconData icon = Icons.history;
                                    Color color = AppColors.primary;

                                    final entity = (log['entity_type'] as String? ?? '').toLowerCase();
                                    if (entity.contains('barber')) {
                                      icon = Icons.content_cut;
                                      color = Colors.green;
                                    } else if (entity.contains('booking')) {
                                      icon = Icons.calendar_today;
                                      color = Colors.blue;
                                    } else if (entity.contains('order')) {
                                      icon = Icons.shopping_bag;
                                      color = Colors.orange;
                                    } else if (entity.contains('delivery')) {
                                      icon = Icons.two_wheeler;
                                      color = Colors.amber;
                                    }

                                    return _buildActivityTile(title, desc, timeStr, icon, color);
                                  }).toList(),
                                ),
                        ),
                        const SizedBox(height: 24),

                        // --- System Health ---
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("System Health", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                            if (_loadingHealth) const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Card(
                          color: AppColors.cardBg,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.border)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Builder(builder: (_) {
                              final comps = _healthData?['components'] as Map<String, dynamic>? ?? {};
                              final isApiOk = (comps['api'] as String? ?? 'healthy') == 'healthy';
                              final isDbOk = (comps['database'] as String? ?? 'healthy') == 'healthy';
                              final isRedisOk = (comps['redis'] as String? ?? 'healthy') == 'healthy';
                              final isWsOk = (comps['websocket'] as String? ?? 'healthy') == 'healthy';
                              final isStorageOk = (comps['storage'] as String? ?? 'healthy') == 'healthy';

                              return Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildHealthIndicator("API", isApiOk),
                                  _buildHealthIndicator("Database", isDbOk),
                                  _buildHealthIndicator("Redis", isRedisOk),
                                  _buildHealthIndicator("WebSocket", isWsOk),
                                  _buildHealthIndicator("Storage", isStorageOk),
                                ],
                              );
                            }),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, {required String title, required String value, required IconData icon, required Color color, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 8),
                Expanded(child: Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis)),
              ],
            ),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionChip(BuildContext context, String label, IconData icon, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ActionChip(
        backgroundColor: AppColors.cardBg,
        side: const BorderSide(color: AppColors.border),
        avatar: Icon(icon, size: 16, color: AppColors.primary),
        label: Text(label, style: const TextStyle(color: AppColors.textPrimary)),
        onPressed: onTap ?? () {
          // Navigate to specific screen based on label
        },
      ),
    );
  }

  Widget _buildActivityTile(String title, String subtitle, String time, IconData icon, Color color) {
    return ListTile(
      leading: CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color, size: 20)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      trailing: Text(time, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
    );
  }

  Widget _buildHealthIndicator(String label, bool isHealthy) {
    return Column(
      children: [
        Icon(isHealthy ? Icons.cloud_done : Icons.cloud_off, color: isHealthy ? Colors.green : Colors.red),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
        Text(isHealthy ? "Online" : "Offline", style: TextStyle(fontSize: 10, color: isHealthy ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
