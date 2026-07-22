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

class _AdminDeliveryScreenState extends State<AdminDeliveryScreen> with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  late TabController _tabController;

  final _tabs = const [
    Tab(text: 'All'),
    Tab(text: 'Pending'),
    Tab(text: 'Approved'),
    Tab(text: 'Suspended'),
    Tab(text: 'Rejected'),
  ];

  String? get _statusFilter {
    switch (_tabController.index) {
      case 1: return 'pending';
      case 2: return 'approved';
      case 3: return 'suspended';
      case 4: return 'rejected';
      default: return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    _searchController.clear();
    context.read<AdminDeliveryBloc>().add(LoadDeliveryPartners(
      page: 1,
      status: _statusFilter,
    ));
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final state = context.read<AdminDeliveryBloc>().state;
      if (state is AdminDeliveryLoaded && !state.hasReachedMax) {
        context.read<AdminDeliveryBloc>().add(LoadDeliveryPartners(
          page: state.currentPage + 1,
          searchQuery: _searchController.text,
          status: _statusFilter,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
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
              context.read<AdminDeliveryBloc>().add(LoadDeliveryPartners(
                page: 1,
                searchQuery: value,
                status: _statusFilter,
              ));
            },
          ),
        ),
        TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: _tabs,
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

  String _approvalStatusLabel() {
    switch (partner.status) {
      case 'pending': return 'PENDING';
      case 'approved': return 'APPROVED';
      case 'rejected': return 'REJECTED';
      case 'suspended': return 'SUSPENDED';
      default: return partner.status.toUpperCase();
    }
  }

  Color _approvalStatusColor() {
    switch (partner.status) {
      case 'pending': return AppColors.warning;
      case 'approved': return AppColors.success;
      case 'rejected': return AppColors.error;
      case 'suspended': return Colors.orange;
      default: return AppColors.textSecondary;
    }
  }

  IconData _approvalStatusIcon() {
    switch (partner.status) {
      case 'pending': return LucideIcons.clock;
      case 'approved': return LucideIcons.checkCircle;
      case 'rejected': return LucideIcons.xCircle;
      case 'suspended': return LucideIcons.pauseCircle;
      default: return LucideIcons.helpCircle;
    }
  }

  void _showRejectDialog(BuildContext context) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Reject Driver', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: reasonController,
          maxLength: 500,
          decoration: const InputDecoration(
            hintText: 'Reason for rejection (required)',
            hintStyle: TextStyle(color: AppColors.textSecondary),
            border: OutlineInputBorder(),
          ),
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) return;
              context.read<AdminDeliveryBloc>().add(UpdateDeliveryStatus(
                partner.id,
                'rejected',
                reason: reasonController.text.trim(),
              ));
              Navigator.pop(ctx);
            },
            child: const Text('Reject', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOffline = partner.availabilityStatus == 'offline';
    final isBusy = partner.availabilityStatus == 'busy';

    Color availabilityColor = AppColors.success;
    if (isOffline) availabilityColor = AppColors.textSecondary;
    if (isBusy) availabilityColor = AppColors.warning;

    final approvalColor = _approvalStatusColor();
    final approvalLabel = _approvalStatusLabel();
    final approvalIcon = _approvalStatusIcon();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Avatar + Name + Rating
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.background,
                  radius: 24,
                  child: Icon(LucideIcons.bike, color: approvalColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        partner.user?.fullName ?? 'Delivery Partner',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${partner.vehicleType} - ${partner.licenseNumber}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Text('⭐ ${partner.rating.toStringAsFixed(1)}',
                    style: const TextStyle(color: AppColors.warning, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),

            // Status badges row
            Row(
              children: [
                _StatusBadge(
                  label: approvalLabel,
                  color: approvalColor,
                  icon: approvalIcon,
                ),
                const SizedBox(width: 8),
                _StatusBadge(
                  label: partner.availabilityStatus.toUpperCase(),
                  color: availabilityColor,
                ),
              ],
            ),

            // Rejection reason
            if (partner.status == 'rejected' && partner.rejectionReason != null && partner.rejectionReason!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(LucideIcons.alertTriangle, color: AppColors.error, size: 14),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        partner.rejectionReason!,
                        style: const TextStyle(color: AppColors.error, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 12),

            // Action buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _buildActions(context),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildActions(BuildContext context) {
    final List<Widget> actions = [];

    switch (partner.status) {
      case 'pending':
        actions.add(_ActionButton(
          label: 'Approve',
          icon: LucideIcons.check,
          color: AppColors.success,
          onPressed: () {
            context.read<AdminDeliveryBloc>().add(UpdateDeliveryStatus(partner.id, 'approved'));
          },
        ));
        actions.add(_ActionButton(
          label: 'Reject',
          icon: LucideIcons.x,
          color: AppColors.error,
          onPressed: () => _showRejectDialog(context),
        ));
        break;

      case 'approved':
        if (partner.availabilityStatus == 'offline') {
          actions.add(_ActionButton(
            label: 'Force Online',
            icon: LucideIcons.power,
            color: AppColors.success,
            onPressed: () {
              context.read<AdminDeliveryBloc>().add(UpdateDeliveryAvailability(partner.id, 'available'));
            },
          ));
        } else {
          actions.add(_ActionButton(
            label: 'Force Offline',
            icon: LucideIcons.powerOff,
            color: AppColors.error,
            onPressed: () {
              context.read<AdminDeliveryBloc>().add(UpdateDeliveryAvailability(partner.id, 'offline'));
            },
          ));
        }
        actions.add(_ActionButton(
          label: 'Suspend',
          icon: LucideIcons.pauseCircle,
          color: Colors.orange,
          onPressed: () {
            context.read<AdminDeliveryBloc>().add(UpdateDeliveryStatus(partner.id, 'suspended'));
          },
        ));
        break;

      case 'suspended':
        actions.add(_ActionButton(
          label: 'Reactivate',
          icon: LucideIcons.refreshCw,
          color: AppColors.success,
          onPressed: () {
            context.read<AdminDeliveryBloc>().add(UpdateDeliveryStatus(partner.id, 'approved'));
          },
        ));
        break;

      case 'rejected':
        // No actions for rejected drivers
        break;
    }

    return actions;
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const _StatusBadge({required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
