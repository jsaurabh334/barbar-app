import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../bloc/admin/admin_delivery_bloc.dart';
import '../../../../data/models/delivery_partner_model.dart';

class AdminDeliveryScreen extends StatefulWidget {
  const AdminDeliveryScreen({super.key});

  @override
  State<AdminDeliveryScreen> createState() => _AdminDeliveryScreenState();
}

class _AdminDeliveryScreenState extends State<AdminDeliveryScreen> {
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
      final state = context.read<AdminDeliveryBloc>().state;
      if (state is AdminDeliveryLoaded && !state.hasReachedMax) {
        context.read<AdminDeliveryBloc>().add(LoadDeliveryPartners(
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
              hintText: 'Search delivery partners...',
              prefixIcon: const Icon(LucideIcons.search, color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (value) {
              context.read<AdminDeliveryBloc>().add(LoadDeliveryPartners(page: 1, searchQuery: value));
            },
          ),
        ),
        Expanded(
          child: BlocConsumer<AdminDeliveryBloc, AdminDeliveryState>(
            listener: (context, state) {
              if (state is AdminDeliveryError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
                );
              }
            },
            builder: (context, state) {
              if (state is AdminDeliveryLoading || state is AdminDeliveryInitial) {
                return const Center(child: CircularProgressIndicator(color: AppColors.primary));
              }

              if (state is AdminDeliveryLoaded) {
                if (state.partners.isEmpty) {
                  return const Center(
                    child: Text('No delivery partners found', style: TextStyle(color: AppColors.textSecondary)),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: state.partners.length + (state.hasReachedMax ? 0 : 1),
                  itemBuilder: (context, index) {
                    if (index >= state.partners.length) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(color: AppColors.primary),
                        ),
                      );
                    }

                    final partner = state.partners[index];
                    return _DeliveryCard(partner: partner);
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

class _DeliveryCard extends StatelessWidget {
  final DeliveryPartnerModel partner;

  const _DeliveryCard({required this.partner});

  @override
  Widget build(BuildContext context) {
    final isOffline = partner.availabilityStatus == 'offline';
    final isBusy = partner.availabilityStatus == 'busy';
    
    Color statusColor = AppColors.success; // available
    if (isOffline) statusColor = AppColors.textSecondary;
    if (isBusy) statusColor = AppColors.warning;

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
            LucideIcons.bike,
            color: statusColor,
          ),
        ),
        title: Text(
          partner.user?.fullName ?? 'Delivery Partner',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('${partner.vehicleType} - ${partner.licenseNumber}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
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
                    partner.availabilityStatus.toUpperCase(),
                    style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                Text('⭐ ${partner.rating}', style: const TextStyle(color: AppColors.warning, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isOffline)
              IconButton(
                icon: const Icon(LucideIcons.powerOff, color: AppColors.error),
                onPressed: () {
                  context.read<AdminDeliveryBloc>().add(UpdateDeliveryStatus(partner.id, 'offline'));
                },
                tooltip: 'Force Offline',
              )
            else
              IconButton(
                icon: const Icon(LucideIcons.power, color: AppColors.success),
                onPressed: () {
                  context.read<AdminDeliveryBloc>().add(UpdateDeliveryStatus(partner.id, 'available'));
                },
                tooltip: 'Force Available',
              ),
          ],
        ),
      ),
    );
  }
}
