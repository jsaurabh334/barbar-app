import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:barbar_app/presentation/screens/admin/vendors/admin_vendors_screen.dart';
import 'package:barbar_app/presentation/bloc/admin/admin_vendors_bloc.dart';
import 'package:barbar_app/presentation/screens/admin/delivery/admin_delivery_screen.dart';
import 'package:barbar_app/presentation/screens/admin/admin_delivery_presence_screen.dart';
import 'package:barbar_app/presentation/bloc/admin/admin_delivery_bloc.dart';
import 'package:barbar_app/presentation/bloc/admin/admin_customers_bloc.dart';
import 'package:barbar_app/domain/repositories/admin_repository.dart';
import '../../core/theme/app_theme.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_event.dart';
import 'admin/customers/admin_customers_screen.dart';
import 'admin/admin_dashboard_screen.dart';
import 'admin/admin_review_moderation_screen.dart';
import 'admin/admin_report_management_screen.dart';

class DisputeCase {
  final String id;
  final String orderNumber;
  final String customerName;
  final String issueType;
  final String description;
  final double amount;
  String status; // pending, resolved, rejected

  DisputeCase({
    required this.id,
    required this.orderNumber,
    required this.customerName,
    required this.issueType,
    required this.description,
    required this.amount,
    required this.status,
  });
}

class AdminConsoleScreen extends StatefulWidget {
  const AdminConsoleScreen({super.key});

  @override
  State<AdminConsoleScreen> createState() => _AdminConsoleScreenState();
}

class _AdminConsoleScreenState extends State<AdminConsoleScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Disputes State
  final List<DisputeCase> _disputes = [
    DisputeCase(
      id: 'disp-1',
      orderNumber: 'ORD-20260603-9A1C',
      customerName: 'Saurabh Jain',
      issueType: 'Damaged Product',
      description: 'Hair clay container seal was broken when delivered. Spill inside package.',
      amount: 499.0,
      status: 'pending',
    ),
    DisputeCase(
      id: 'disp-2',
      orderNumber: 'ORD-20260528-4K2P',
      customerName: 'Aditya Sen',
      issueType: 'Barber No-Show',
      description: 'Barber was not at shop during slot timing. Waited 30 minutes.',
      amount: 399.0,
      status: 'pending',
    ),
  ];

  // Settings State Controllers
  final _commissionController = TextEditingController(text: '10.0');
  final _platformFeeController = TextEditingController(text: '5.0');
  final _freeDeliveryThresholdController = TextEditingController(text: '499');
  final _deliveryChargeController = TextEditingController(text: '49');
  
  bool _autoCancelNoShow = true;
  bool _enableFCMAlerts = true;

  // Dialog Remarks Controller
  final _remarksController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 8, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _remarksController.dispose();
    _commissionController.dispose();
    _platformFeeController.dispose();
    _freeDeliveryThresholdController.dispose();
    _deliveryChargeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        backgroundColor: AppColors.surface,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: AppColors.cardBg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'SUPER ADMIN',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Management Console',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            _buildDrawerItem(LucideIcons.layoutDashboard, 'Dashboard (Barbers)', 0),
            _buildDrawerItem(LucideIcons.users, 'Customers', 1),
            _buildDrawerItem(LucideIcons.store, 'Vendors', 2),
            _buildDrawerItem(LucideIcons.bike, 'Delivery', 3),
            _buildDrawerItem(LucideIcons.activity, 'Delivery Drivers', 9),
            _buildDrawerItem(LucideIcons.scale, 'Disputes', 4),
            _buildDrawerItem(LucideIcons.messageSquare, 'Reviews', 5),
            _buildDrawerItem(LucideIcons.flag, 'Reports', 6),
            _buildDrawerItem(LucideIcons.settings, 'Settings', 7),
            _buildDrawerItem(LucideIcons.activity, 'Analytics', 8),
          ],
        ),
      ),
      appBar: AppBar(
        title: const Text(
          'SUPER ADMIN CONSOLE',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.logOut),
            onPressed: () => context.read<AuthBloc>().add(LogoutRequested()),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          const AdminDashboardScreen(),
          BlocProvider(
            create: (context) => AdminCustomersBloc(
              adminRepository: context.read<AdminRepository>(),
            )..add(const LoadCustomers()),
            child: const AdminCustomersScreen(),
          ),
          BlocProvider(
            create: (context) => AdminVendorsBloc(
              adminRepository: context.read<AdminRepository>(),
            )..add(const LoadVendors()),
            child: const AdminVendorsScreen(),
          ),
          BlocProvider(
            create: (context) => AdminDeliveryBloc(
              adminRepository: context.read<AdminRepository>(),
            )..add(const LoadDeliveryPartners()),
            child: const AdminDeliveryScreen(),
          ),
          _buildDisputesTab(),
          AdminReviewModerationScreen(
            adminRepository: context.read<AdminRepository>(),
          ),
          AdminReportManagementScreen(
            adminRepository: context.read<AdminRepository>(),
          ),
          _buildSettingsTab(),
          _buildAnalyticsTab(),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, int index) {
    final isSelected = _tabController.index == index;
    return ListTile(
      leading: Icon(icon, color: isSelected ? AppColors.primary : Colors.grey),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? AppColors.primary : Colors.grey,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: AppColors.primary.withValues(alpha: 0.1),
      onTap: () {
        Navigator.pop(context); // close drawer
        if (index == 9) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDeliveryPresenceScreen()));
        } else {
          _tabController.animateTo(index);
        }
      },
    );
  }

  // ================= Disputes Tab =================
  Widget _buildDisputesTab() {
    final pendingDisputes = _disputes.where((d) => d.status == 'pending').toList();
    if (pendingDisputes.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.checkCircle, size: 64, color: AppColors.success),
            SizedBox(height: 16),
            Text(
              'No active disputes or refund claims pending.',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: pendingDisputes.length,
      itemBuilder: (context, index) {
        return _buildDisputeCard(pendingDisputes[index]);
      },
    );
  }

  Widget _buildDisputeCard(DisputeCase d) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
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
              Text(
                'Dispute for: ${d.orderNumber}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Text(
                '₹${d.amount.toInt()}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('Customer: ${d.customerName}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          Text('Reason: ${d.issueType}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amberAccent, fontSize: 12)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              d.description,
              style: const TextStyle(fontSize: 12, height: 1.4),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                  ),
                  onPressed: () => _resolveDispute(d.id, 'rejected'),
                  child: const FittedBox(child: Text('REJECT REFUND')),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () => _resolveDispute(d.id, 'resolved'),
                  child: const FittedBox(child: Text('APPROVE REFUND')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _resolveDispute(String id, String status) {
    _remarksController.clear();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(status == 'resolved' ? 'Approve Refund Escrow Split' : 'Reject Refund Claim'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _remarksController,
                decoration: const InputDecoration(labelText: 'Audit trail / Remarks'),
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
                setState(() {
                  _disputes.firstWhere((d) => d.id == id).status = status;
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Dispute has been marked as ${status.toUpperCase()}'),
                    backgroundColor: status == 'resolved' ? AppColors.success : AppColors.error,
                  ),
                );
              },
              child: const Text('CONFIRM'),
            ),
          ],
        );
      },
    );
  }

  // ================= Settings Tab =================
  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'FEE STRUCTURES',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.5, color: AppColors.primary),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _commissionController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Commission Rate (%)',
              prefixIcon: Icon(LucideIcons.percent, size: 20),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _platformFeeController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Platform Convenience Fee (₹)',
              prefixIcon: Icon(LucideIcons.dollarSign, size: 20),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'HYPERLOCAL DELIVERY PARAMETERS',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.5, color: AppColors.primary),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _freeDeliveryThresholdController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Free Delivery Minimum Amount (₹)',
              prefixIcon: Icon(LucideIcons.package, size: 20),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _deliveryChargeController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Standard Delivery Charge (₹)',
              prefixIcon: Icon(LucideIcons.truck, size: 20),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'GLOBAL ENGINE FLAGS',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.5, color: AppColors.primary),
          ),
          const SizedBox(height: 6),
          SwitchListTile(
            title: const Text('Auto-Cancel No-Shows'),
            subtitle: const Text('Cancel barber booking automatically after 15 mins delay'),
            value: _autoCancelNoShow,
            activeColor: AppColors.primary,
            onChanged: (val) {
              setState(() {
                _autoCancelNoShow = val;
              });
            },
          ),
          SwitchListTile(
            title: const Text('Enable FCM System Alerts'),
            subtitle: const Text('Push alerts globally for server status adjustments'),
            value: _enableFCMAlerts,
            activeColor: AppColors.primary,
            onChanged: (val) {
              setState(() {
                _enableFCMAlerts = val;
              });
            },
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Global platform settings updated successfully!'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: const Text('SAVE GLOBAL SETTINGS', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
          ),
        ],
      ),
    );
  }

  // ================= Analytics Tab =================
  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Stat grid
          Row(
            children: [
              Expanded(
                child: _buildMetricCard('Total Sales', '₹1,28,450', LucideIcons.trendingUp),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard('Platform Revenue', '₹12,845', LucideIcons.coins),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard('Total Customers', '1,240', LucideIcons.users),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard('Active Providers', '116', LucideIcons.scissors),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'SYSTEM METRICS & HEALTH',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.5, color: AppColors.primary),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: const Column(
              children: [
                _TelemetryRow(label: 'CPU Usage', value: '14.2%', status: 'HEALTHY'),
                Divider(height: 20, color: AppColors.border),
                _TelemetryRow(label: 'RAM Allocation', value: '512 MB / 2.0 GB', status: 'HEALTHY'),
                Divider(height: 20, color: AppColors.border),
                _TelemetryRow(label: 'Active Goroutines', value: '48 threads', status: 'HEALTHY'),
                Divider(height: 20, color: AppColors.border),
                _TelemetryRow(label: 'DB Connections Pool', value: '10/20 limits', status: 'HEALTHY'),
                Divider(height: 20, color: AppColors.border),
                _TelemetryRow(label: 'Redis Cache Hit Rate', value: '98.4%', status: 'EXCELLENT'),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _TelemetryRow extends StatelessWidget {
  final String label;
  final String value;
  final String status;

  const _TelemetryRow({
    required this.label,
    required this.value,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        Row(
          children: [
            Text(value, style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.greenAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                status,
                style: const TextStyle(color: Colors.greenAccent, fontSize: 8, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        )
      ],
    );
  }
}
