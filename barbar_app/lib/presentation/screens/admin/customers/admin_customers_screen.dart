import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../bloc/admin/admin_customers_bloc.dart';
import '../../../../domain/repositories/admin_repository.dart';
import '../../../../data/models/user_model.dart';
import 'admin_customer_details_screen.dart';

class AdminCustomersScreen extends StatelessWidget {
  const AdminCustomersScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AdminCustomersBloc(
        adminRepository: context.read<AdminRepository>(),
      )..add(const LoadCustomers()),
      child: const _CustomersView(),
    );
  }
}

class _CustomersView extends StatefulWidget {
  const _CustomersView({Key? key}) : super(key: key);

  @override
  State<_CustomersView> createState() => _CustomersViewState();
}

class _CustomersViewState extends State<_CustomersView> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  final List<String> _statusFilters = ['active', 'blocked', 'deleted'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    _fetchData();
  }

  void _onSearchChanged(String query) {
    _fetchData();
  }

  void _fetchData() {
    final status = _statusFilters[_tabController.index];
    context.read<AdminCustomersBloc>().add(LoadCustomers(page: 1, searchQuery: _searchController.text, status: status));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Manage Customers'),
        backgroundColor: Colors.black,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Blocked'),
            Tab(text: 'Deleted'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search by name, phone, email, ID...',
                hintStyle: TextStyle(color: Colors.grey[500]),
                prefixIcon: const Icon(LucideIcons.search, color: Colors.grey),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: BlocBuilder<AdminCustomersBloc, AdminCustomersState>(
              builder: (context, state) {
                if (state is AdminCustomersLoading || state is AdminCustomersInitial) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }

                if (state is AdminCustomersError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.alertTriangle, color: AppColors.error, size: 48),
                        const SizedBox(height: 16),
                        Text(state.message, style: const TextStyle(color: Colors.white)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchData,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (state is AdminCustomersLoaded) {
                  if (state.customers.isEmpty) {
                    return Center(
                      child: Text('No customers found.', style: TextStyle(color: Colors.grey[500], fontSize: 16)),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: state.customers.length + (state.hasReachedMax ? 0 : 1),
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      if (index >= state.customers.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(color: AppColors.primary),
                          ),
                        );
                      }

                      final customer = state.customers[index];
                      final isBlocked = customer.status.toLowerCase() == 'blocked';

                      return InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AdminCustomerDetailsScreen(customerId: customer.id),
                            ),
                          ).then((_) {
                            // Refresh list when coming back
                            _fetchData();
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[800]!),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.grey[800],
                                radius: 24,
                                backgroundImage: customer.avatar != null && customer.avatar!.isNotEmpty ? NetworkImage(customer.avatar!) : null,
                                child: (customer.avatar == null || customer.avatar!.isEmpty) ? const Icon(LucideIcons.user, color: Colors.grey) : null,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      customer.fullName,
                                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      customer.phone,
                                      style: TextStyle(color: Colors.grey[400], fontSize: 14),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isBlocked ? AppColors.error.withOpacity(0.2) : AppColors.success.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            customer.status.toUpperCase(),
                                            style: TextStyle(
                                              color: isBlocked ? AppColors.error : AppColors.success,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(isBlocked ? LucideIcons.unlock : LucideIcons.lock, color: isBlocked ? AppColors.success : AppColors.error),
                                tooltip: isBlocked ? 'Unblock Customer' : 'Block Customer',
                                onPressed: () {
                                  _showConfirmationDialog(context, customer, isBlocked);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showConfirmationDialog(BuildContext context, UserModel customer, bool isBlocked) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(isBlocked ? 'Unblock Customer?' : 'Block Customer?', style: const TextStyle(color: Colors.white)),
        content: Text(
          isBlocked 
            ? 'Are you sure you want to unblock ${customer.fullName}?' 
            : 'Are you sure you want to block ${customer.fullName}? They will not be able to log in.',
          style: TextStyle(color: Colors.grey[400]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isBlocked ? AppColors.success : AppColors.error,
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              if (isBlocked) {
                context.read<AdminCustomersBloc>().add(UnblockCustomer(customer.id));
              } else {
                context.read<AdminCustomersBloc>().add(BlockCustomer(customer.id));
              }
            },
            child: Text(isBlocked ? 'UNBLOCK' : 'BLOCK'),
          ),
        ],
      ),
    );
  }
}
