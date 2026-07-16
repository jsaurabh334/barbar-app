import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../bloc/admin/admin_vendors_bloc.dart';
import '../../../../data/models/vendor_model.dart';

class AdminVendorsScreen extends StatefulWidget {
  const AdminVendorsScreen({super.key});

  @override
  State<AdminVendorsScreen> createState() => _AdminVendorsScreenState();
}

class _AdminVendorsScreenState extends State<AdminVendorsScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final state = context.read<AdminVendorsBloc>().state;
      if (state is AdminVendorsLoaded && !state.hasReachedMax) {
        context.read<AdminVendorsBloc>().add(LoadVendors(
          page: state.currentPage + 1,
          searchQuery: _searchController.text,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search vendors by name or city...',
              prefixIcon: const Icon(LucideIcons.search, color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (value) {
              context.read<AdminVendorsBloc>().add(LoadVendors(page: 1, searchQuery: value));
            },
          ),
        ),
        Expanded(
          child: BlocConsumer<AdminVendorsBloc, AdminVendorsState>(
            listener: (context, state) {
              if (state is AdminVendorsError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
                );
              }
            },
            builder: (context, state) {
              if (state is AdminVendorsLoading || state is AdminVendorsInitial) {
                return const Center(child: CircularProgressIndicator(color: AppColors.primary));
              }

              if (state is AdminVendorsLoaded) {
                if (state.vendors.isEmpty) {
                  return const Center(
                    child: Text('No vendors found', style: TextStyle(color: AppColors.textSecondary)),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: state.vendors.length + (state.hasReachedMax ? 0 : 1),
                  itemBuilder: (context, index) {
                    if (index >= state.vendors.length) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(color: AppColors.primary),
                        ),
                      );
                    }

                    final vendor = state.vendors[index];
                    return _VendorCard(vendor: vendor);
                  },
                );
              }

              return const SizedBox.shrink();
            },
          ),
        ),
      ],
    );
  }
}

class _VendorCard extends StatelessWidget {
  final VendorModel vendor;

  const _VendorCard({required this.vendor});

  @override
  Widget build(BuildContext context) {
    final isApproved = vendor.status == 'approved';
    final isPending = vendor.status == 'pending';
    
    Color statusColor = AppColors.warning;
    if (isApproved) statusColor = AppColors.success;
    if (vendor.status == 'suspended') statusColor = AppColors.error;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: AppColors.background,
          radius: 24,
          child: Icon(
            LucideIcons.store,
            color: isApproved ? AppColors.success : AppColors.textSecondary,
          ),
        ),
        title: Text(
          vendor.storeName,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(vendor.city ?? '', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    vendor.status.toUpperCase(),
                    style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                Text('⭐ ${vendor.rating}', style: const TextStyle(color: AppColors.warning, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isPending)
              IconButton(
                icon: const Icon(LucideIcons.checkCircle, color: AppColors.success),
                onPressed: () {
                  context.read<AdminVendorsBloc>().add(ApproveVendor(vendor.id));
                },
                tooltip: 'Approve Vendor',
              ),
            if (isApproved)
              IconButton(
                icon: const Icon(LucideIcons.ban, color: AppColors.error),
                onPressed: () {
                  _showSuspendDialog(context, vendor);
                },
                tooltip: 'Suspend Vendor',
              ),
          ],
        ),
      ),
    );
  }

  void _showSuspendDialog(BuildContext context, VendorModel vendor) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Suspend Vendor?', style: TextStyle(color: Colors.white)),
        content: Text('Are you sure you want to suspend ${vendor.storeName}? Their products will no longer be visible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AdminVendorsBloc>().add(SuspendVendor(vendor.id));
            },
            child: const Text('SUSPEND'),
          ),
        ],
      ),
    );
  }
}
