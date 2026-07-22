import 'package:flutter/material.dart';
import 'package:barbar_app/presentation/bloc/admin/admin_bookings_bloc.dart';
import 'package:barbar_app/presentation/screens/admin/admin_bookings_screen.dart';
import 'package:barbar_app/presentation/bloc/admin/admin_orders_bloc.dart';
import 'package:barbar_app/presentation/screens/admin/admin_orders_screen.dart';
import 'package:barbar_app/presentation/bloc/admin/admin_finance_bloc.dart';
import 'package:barbar_app/presentation/screens/admin/admin_refunds_screen.dart';
import 'package:barbar_app/presentation/screens/admin/admin_tax_settings_screen.dart';
import 'package:barbar_app/presentation/bloc/admin/admin_reports_bloc.dart';
import 'package:barbar_app/presentation/screens/admin/admin_revenue_analytics_screen.dart';
import 'package:barbar_app/presentation/bloc/admin/admin_settlements_bloc.dart';
import 'package:barbar_app/presentation/screens/admin/finance/admin_settlements_screen.dart';
import 'package:barbar_app/presentation/bloc/admin/admin_wallet_bloc.dart';
import 'package:barbar_app/presentation/screens/admin/finance/admin_wallet_management_screen.dart';
import 'package:barbar_app/presentation/bloc/admin/admin_banners_bloc.dart';
import 'package:barbar_app/presentation/screens/admin/admin_banners_screen.dart';
import 'package:barbar_app/presentation/bloc/admin/admin_campaigns_bloc.dart';
import 'package:barbar_app/presentation/screens/admin/admin_campaigns_screen.dart';
import 'package:barbar_app/presentation/bloc/admin/admin_cms_bloc.dart';
import 'package:barbar_app/presentation/screens/admin/admin_cms_screen.dart';

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
import 'notifications_screen.dart';
import 'profile_screen.dart';

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
    _tabController = TabController(length: 16, vsync: this);
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
            _buildDrawerItem(LucideIcons.calendarCheck, 'Bookings', 1),
            _buildDrawerItem(LucideIcons.shoppingCart, 'Orders', 2),
            _buildDrawerItem(LucideIcons.users, 'Customers', 3),
            _buildDrawerItem(LucideIcons.store, 'Vendors', 4),
            _buildDrawerItem(LucideIcons.bike, 'Delivery', 5),
            _buildDrawerItem(LucideIcons.activity, 'Delivery Drivers', 99), // 99 for direct navigation
            _buildDrawerItem(LucideIcons.messageSquare, 'Reviews', 6),
            _buildDrawerItem(LucideIcons.flag, 'Reports', 7),
            _buildDrawerItem(LucideIcons.receipt, 'Refunds', 8),
            _buildDrawerItem(LucideIcons.receipt, 'Tax Settings', 9),
            _buildDrawerItem(LucideIcons.activity, 'Revenue Analytics', 10),
            _buildDrawerItem(LucideIcons.banknote, 'Settlements', 11),
            _buildDrawerItem(LucideIcons.wallet, 'Wallets', 12),
            _buildDrawerItem(LucideIcons.image, 'Banners', 13),
            _buildDrawerItem(LucideIcons.megaphone, 'Campaigns', 14),
            _buildDrawerItem(LucideIcons.fileText, 'CMS', 15),
          ],
        ),
      ),
      appBar: AppBar(
        title: const Text(
          'Admin Console',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.bell),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen(role: 'admin')),
              );
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          const AdminDashboardScreen(),
          BlocProvider(
            create: (context) => AdminBookingsBloc(adminRepository: context.read<AdminRepository>())..add(const LoadBookings()),
            child: const AdminBookingsScreen(),
          ),
          BlocProvider(
            create: (context) => AdminOrdersBloc(adminRepository: context.read<AdminRepository>())..add(const LoadOrders()),
            child: const AdminOrdersScreen(),
          ),
          BlocProvider(
            create: (context) => AdminCustomersBloc(adminRepository: context.read<AdminRepository>())..add(const LoadCustomers()),
            child: const AdminCustomersScreen(),
          ),
          BlocProvider(
            create: (context) => AdminVendorsBloc(adminRepository: context.read<AdminRepository>())..add(const LoadVendors()),
            child: const AdminVendorsScreen(),
          ),
          BlocProvider(
            create: (context) => AdminDeliveryBloc(adminRepository: context.read<AdminRepository>())..add(const LoadDeliveryPartners()),
            child: const AdminDeliveryScreen(),
          ),
          AdminReviewModerationScreen(adminRepository: context.read<AdminRepository>()),
          AdminReportManagementScreen(adminRepository: context.read<AdminRepository>()),
          BlocProvider(
            create: (context) => AdminFinanceBloc(adminRepository: context.read<AdminRepository>())..add(const LoadRefunds()),
            child: const AdminRefundsScreen(),
          ),
          BlocProvider(
            create: (context) => AdminFinanceBloc(adminRepository: context.read<AdminRepository>())..add(const LoadTaxSettings()),
            child: const AdminTaxSettingsScreen(),
          ),
          BlocProvider(
            create: (context) => AdminReportsBloc(adminRepository: context.read<AdminRepository>())..add(LoadRevenueReport()),
            child: const AdminRevenueAnalyticsScreen(),
          ),
          BlocProvider(
            create: (context) => AdminSettlementsBloc(adminRepository: context.read<AdminRepository>())..add(LoadSettlements()),
            child: const AdminSettlementsScreen(),
          ),
          BlocProvider(
            create: (context) => AdminWalletBloc(adminRepository: context.read<AdminRepository>())..add(LoadAdminWallets()),
            child: const AdminWalletManagementScreen(),
          ),
          BlocProvider(
            create: (context) => AdminBannersBloc(adminRepository: context.read<AdminRepository>())..add(LoadBanners()),
            child: const AdminBannersScreen(),
          ),
          BlocProvider(
            create: (context) => AdminCampaignsBloc(adminRepository: context.read<AdminRepository>())..add(LoadCampaigns()),
            child: const AdminCampaignsScreen(),
          ),
          BlocProvider(
            create: (context) => AdminCmsBloc(adminRepository: context.read<AdminRepository>())..add(LoadCmsPages()),
            child: const AdminCmsScreen(),
          ),
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
        if (index == 99) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDeliveryPresenceScreen()));
        } else {
          _tabController.animateTo(index);
        }
      },
    );
  }

  }
