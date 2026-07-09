import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:barbar_app/presentation/bloc/admin/admin_dashboard_bloc.dart';
import 'package:barbar_app/domain/repositories/admin_repository.dart';
import 'package:barbar_app/presentation/screens/admin/pending_barbers_screen.dart';
import 'package:barbar_app/presentation/screens/admin/active_barbers_screen.dart';
import 'package:barbar_app/core/theme/app_theme.dart';

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
  @override
  Widget build(BuildContext context) {
    final todayStr = DateFormat('dd MMMM yyyy').format(DateTime.now());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Admin Dashboard', style: TextStyle(color: AppColors.textPrimary)),
        actions: [
          IconButton(icon: const Icon(Icons.notifications, color: AppColors.textPrimary), onPressed: () {}),
          const CircleAvatar(
            backgroundColor: AppColors.primary,
            child: Icon(Icons.person, color: Colors.black),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          context.read<AdminDashboardBloc>().add(LoadDashboardData());
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Today: $todayStr", style: const TextStyle(color: AppColors.textSecondary)),
                  const Text("Last Sync: Just Now", style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 24),

              BlocBuilder<AdminDashboardBloc, AdminDashboardState>(
                builder: (context, state) {
                  if (state is AdminDashboardLoading || state is AdminDashboardInitial) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is AdminDashboardError) {
                    return Center(
                      child: Column(
                        children: [
                          const Icon(Icons.error, color: Colors.red, size: 48),
                          const SizedBox(height: 8),
                          Text("Failed to load dashboard: ${state.message}"),
                          TextButton(
                            onPressed: () => context.read<AdminDashboardBloc>().add(LoadDashboardData()),
                            child: const Text("Retry"),
                          )
                        ],
                      ),
                    );
                  }

                  if (state is AdminDashboardLoaded) {
                    final stats = state.stats;

                    // Calculate total alerts
                    int alertCount = 0;
                    if (stats.pendingBarbers > 0) alertCount++;
                    if (stats.pendingReports > 0) alertCount++;
                    if (stats.pendingKyc > 0) alertCount++;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- Alerts Section ---
                        if (alertCount > 0) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.warning_amber_rounded, color: Colors.red),
                                    const SizedBox(width: 8),
                                    Text("$alertCount Alerts requiring attention", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (stats.pendingBarbers > 0) Text("⚠ ${stats.pendingBarbers} Pending Barbers", style: const TextStyle(color: Colors.red)),
                                if (stats.pendingReports > 0) Text("⚠ ${stats.pendingReports} Reported Shops", style: const TextStyle(color: Colors.red)),
                                if (stats.pendingKyc > 0) Text("⚠ ${stats.pendingKyc} Pending KYC", style: const TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // --- KPI Cards ---
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.5,
                          children: [
                            _buildStatCard(
                              context,
                              title: "Pending Barbers",
                              value: stats.pendingBarbers.toString(),
                              icon: Icons.store_mall_directory_outlined,
                              color: Colors.orange,
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PendingBarbersScreen())),
                            ),
                            _buildStatCard(
                              context,
                              title: "Approved Barbers",
                              value: stats.approvedBarbers.toString(),
                              icon: Icons.check_circle_outline,
                              color: Colors.green,
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ActiveBarbersScreen())),
                            ),
                            _buildStatCard(context, title: "Customers", value: stats.totalCustomers.toString(), icon: Icons.people_outline, color: Colors.blue),
                            _buildStatCard(context, title: "Today's Bookings", value: stats.todayBookings.toString(), icon: Icons.calendar_today, color: Colors.purple),
                            _buildStatCard(context, title: "Today's Revenue", value: "₹${stats.todayRevenue.toStringAsFixed(0)}", icon: Icons.currency_rupee, color: Colors.indigo),
                            _buildStatCard(context, title: "Live Queue", value: stats.liveQueue.toString(), icon: Icons.queue, color: Colors.teal),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // --- Quick Actions ---
                        const Text("Quick Actions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildActionChip(context, "Approve Barbers", Icons.check),
                              _buildActionChip(context, "Customers", Icons.people),
                              _buildActionChip(context, "Vendors", Icons.storefront),
                              _buildActionChip(context, "Reports", Icons.report),
                              _buildActionChip(context, "Analytics", Icons.analytics),
                              _buildActionChip(context, "Settings", Icons.settings),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // --- Live Activity Feed (Mocked) ---
                        const Text("Live Activity Feed", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        const SizedBox(height: 12),
                        Card(
                          color: AppColors.cardBg,
                          child: Column(
                            children: [
                              _buildActivityTile("Raj Hair Studio", "Approved", "2 min ago", Icons.check_circle, Colors.green),
                              _buildActivityTile("ABC Salon", "Submitted Application", "5 min ago", Icons.upload_file, Colors.orange),
                              _buildActivityTile("Customer booking", "Hair Cut", "10 min ago", Icons.calendar_today, Colors.blue),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // --- System Health ---
                        const Text("System Health", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        const SizedBox(height: 12),
                        Card(
                          color: AppColors.cardBg,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildHealthIndicator("API", true),
                                _buildHealthIndicator("Database", true),
                                _buildHealthIndicator("Redis", true),
                                _buildHealthIndicator("WebSocket", true),
                              ],
                            ),
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

  Widget _buildActionChip(BuildContext context, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ActionChip(
        backgroundColor: AppColors.cardBg,
        side: const BorderSide(color: AppColors.border),
        avatar: Icon(icon, size: 16, color: AppColors.primary),
        label: Text(label, style: const TextStyle(color: AppColors.textPrimary)),
        onPressed: () {
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
