import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_theme.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_event.dart';

class KycDocument {
  final String id;
  final String applicantName;
  final String role; // barber or vendor
  final String docType; // PAN Card, Shop License
  final String fileUrl;
  String status;

  KycDocument({
    required this.id,
    required this.applicantName,
    required this.role,
    required this.docType,
    required this.fileUrl,
    required this.status,
  });
}

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

  // KYC State
  final List<KycDocument> _documents = [
    KycDocument(id: 'kyc-1', applicantName: 'John Barber', role: 'barber', docType: 'Shop License', fileUrl: 'https://images.unsplash.com/photo-1503951914875-452162b0f3f1', status: 'pending'),
    KycDocument(id: 'kyc-2', applicantName: 'Acme Products', role: 'vendor', docType: 'PAN Card Registry', fileUrl: 'https://images.unsplash.com/photo-1599351431202-1e0f0137899a', status: 'pending'),
  ];

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
    _tabController = TabController(length: 4, vsync: this);
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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(LucideIcons.shieldAlert), text: 'KYC'),
            Tab(icon: Icon(LucideIcons.scale), text: 'Disputes'),
            Tab(icon: Icon(LucideIcons.settings), text: 'Settings'),
            Tab(icon: Icon(LucideIcons.activity), text: 'Analytics'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildKycTab(),
          _buildDisputesTab(),
          _buildSettingsTab(),
          _buildAnalyticsTab(),
        ],
      ),
    );
  }

  // ================= KYC Tab =================
  Widget _buildKycTab() {
    final pendingDocs = _documents.where((d) => d.status == 'pending').toList();
    if (pendingDocs.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.checkSquare, size: 64, color: AppColors.success),
            SizedBox(height: 16),
            Text(
              'All KYC documents verified!',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: pendingDocs.length,
      itemBuilder: (context, index) {
        return _buildKycCard(pendingDocs[index]);
      },
    );
  }

  Widget _buildKycCard(KycDocument doc) {
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
              Text(doc.applicantName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  doc.role.toUpperCase(),
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('Doc Type: ${doc.docType}', style: const TextStyle(color: AppColors.textSecondary)),
          const Divider(height: 24, color: AppColors.border),
          SizedBox(
            height: 120,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                doc.fileUrl,
                fit: BoxFit.cover,
                errorBuilder: (c, _, __) => const Icon(LucideIcons.file),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                  ),
                  onPressed: () => _verifyKycDocument(doc.id, 'rejected'),
                  child: const Text('REJECT'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () => _verifyKycDocument(doc.id, 'approved'),
                  child: const Text('APPROVE'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _verifyKycDocument(String id, String status) {
    _remarksController.clear();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(status == 'approved' ? 'Approve Verification' : 'Reject Verification'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _remarksController,
                decoration: const InputDecoration(labelText: 'Remarks / Comments'),
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
                  _documents.firstWhere((d) => d.id == id).status = status;
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Document status updated to ${status.toUpperCase()}'),
                    backgroundColor: status == 'approved' ? AppColors.success : AppColors.error,
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
                  child: const Text('REJECT REFUND'),
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
                  child: const Text('APPROVE REFUND'),
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
