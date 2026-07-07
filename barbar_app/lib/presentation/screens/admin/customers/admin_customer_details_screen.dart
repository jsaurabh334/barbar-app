import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../bloc/admin/admin_customer_details_bloc.dart';
import '../../../../domain/repositories/admin_repository.dart';

class AdminCustomerDetailsScreen extends StatelessWidget {
  final String customerId;

  const AdminCustomerDetailsScreen({Key? key, required this.customerId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AdminCustomerDetailsBloc(
        adminRepository: context.read<AdminRepository>(),
      )..add(LoadCustomerDetails(customerId)),
      child: const _DetailsView(),
    );
  }
}

class _DetailsView extends StatelessWidget {
  const _DetailsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Customer Details'),
        backgroundColor: Colors.black,
      ),
      body: BlocBuilder<AdminCustomerDetailsBloc, AdminCustomerDetailsState>(
        builder: (context, state) {
          if (state is AdminCustomerDetailsLoading || state is AdminCustomerDetailsInitial) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          if (state is AdminCustomerDetailsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.alertTriangle, color: AppColors.error, size: 48),
                  const SizedBox(height: 16),
                  Text(state.message, style: const TextStyle(color: Colors.white)),
                ],
              ),
            );
          }

          if (state is AdminCustomerDetailsLoaded) {
            final details = state.details;
            final customer = details.customer;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Header
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey[800],
                          backgroundImage: customer.avatar != null ? NetworkImage(customer.avatar!) : null,
                          child: customer.avatar == null
                              ? const Icon(LucideIcons.user, size: 40, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(height: 16),
                        Text(customer.fullName, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(customer.phone, style: TextStyle(color: Colors.grey[400], fontSize: 16)),
                        if (customer.email != null) ...[
                          const SizedBox(height: 4),
                          Text(customer.email!, style: TextStyle(color: Colors.grey[400], fontSize: 16)),
                        ],
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getStatusColor(customer.status).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            customer.status.toUpperCase(),
                            style: TextStyle(color: _getStatusColor(customer.status), fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Actions
                  _buildActions(context, customer.id, customer.status),
                  const SizedBox(height: 32),

                  // Statistics
                  const Text('Statistics', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildStatCard('Bookings', details.totalBookings.toString(), LucideIcons.calendar)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildStatCard('Spent', '₹${details.spent.toStringAsFixed(2)}', LucideIcons.wallet)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildStatCard('Completed', details.completedBookings.toString(), LucideIcons.checkCircle2)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildStatCard('Cancelled', details.cancelledBookings.toString(), LucideIcons.xCircle)),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Wallet
                  const Text('Wallet', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Balance', style: TextStyle(color: Colors.grey[400], fontSize: 14)),
                        const SizedBox(height: 8),
                        Text('₹${details.walletBalance.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Bookings (Mock list for now, later mapped to real models)
                  const Text('Recent Bookings', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  if (details.bookings.isEmpty)
                    const Text('No recent bookings', style: TextStyle(color: Colors.grey))
                  else
                    ...details.bookings.take(3).map((b) => _buildMockBookingCard()),

                  const SizedBox(height: 32),

                  // Reviews (Mock list for now)
                  const Text('Reviews Given', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  if (details.reviews.isEmpty)
                    const Text('No reviews given', style: TextStyle(color: Colors.grey))
                  else
                    ...details.reviews.take(3).map((r) => _buildMockReviewCard()),
                  
                  const SizedBox(height: 40),
                ],
              ),
            );
          }

          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildActions(BuildContext context, String customerId, String status) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (status == 'active')
          ElevatedButton.icon(
            onPressed: () => context.read<AdminCustomerDetailsBloc>().add(DetailBlockCustomer(customerId)),
            icon: const Icon(LucideIcons.ban),
            label: const Text('Block'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          ),
        if (status == 'blocked')
          ElevatedButton.icon(
            onPressed: () => context.read<AdminCustomerDetailsBloc>().add(DetailUnblockCustomer(customerId)),
            icon: const Icon(LucideIcons.checkCircle),
            label: const Text('Unblock'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          ),
        const SizedBox(width: 16),
        if (status != 'deleted')
          ElevatedButton.icon(
            onPressed: () => context.read<AdminCustomerDetailsBloc>().add(DetailDeleteCustomer(customerId)),
            icon: const Icon(LucideIcons.trash2),
            label: const Text('Soft Delete'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
          ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(color: Colors.grey[400], fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildMockBookingCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Haircut & Beard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Mock Barber', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
            ],
          ),
          const Text('₹300', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildMockReviewCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(LucideIcons.star, color: Colors.amber, size: 16),
              Icon(LucideIcons.star, color: Colors.amber, size: 16),
              Icon(LucideIcons.star, color: Colors.amber, size: 16),
              Icon(LucideIcons.star, color: Colors.amber, size: 16),
              Icon(LucideIcons.starHalf, color: Colors.amber, size: 16),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Great service, very professional!', style: TextStyle(color: Colors.white)),
          const SizedBox(height: 8),
          Text('For: Mock Barber', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'blocked':
        return Colors.orange;
      case 'deleted':
        return AppColors.error;
      default:
        return Colors.grey;
    }
  }
}
