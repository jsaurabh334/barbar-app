import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:barbar_app/presentation/bloc/admin/admin_promotions_bloc.dart';
import 'package:barbar_app/core/theme/app_theme.dart';

class AdminPromotionsScreen extends StatefulWidget {
  const AdminPromotionsScreen({super.key});
  @override
  State<AdminPromotionsScreen> createState() => _AdminPromotionsScreenState();
}

class _AdminPromotionsScreenState extends State<AdminPromotionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: AppColors.cardBg,
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.primary,
            tabs: const [
              Tab(text: 'Coupons'),
              Tab(text: 'Featured'),
              Tab(text: 'Templates'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _CouponsTab(),
              _FeaturedListingsTab(),
              _NotificationTemplatesTab(),
            ],
          ),
        ),
      ],
    );
  }
}

class _CouponsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminPromotionsBloc, AdminPromotionsState>(
      builder: (context, state) {
        if (state is AdminPromotionsLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is AdminPromotionsError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(state.message, style: const TextStyle(color: AppColors.error)),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => context.read<AdminPromotionsBloc>().add(const LoadCoupons()),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        if (state is CouponsLoaded) {
          return _CouponListView(coupons: state.coupons);
        }
        return const Center(child: Text('Tap refresh to load coupons'));
      },
    );
  }
}

class _CouponListView extends StatelessWidget {
  final List<dynamic> coupons;
  const _CouponListView({required this.coupons});

  @override
  Widget build(BuildContext context) {
    if (coupons.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.ticket, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No coupons found', style: TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: coupons.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ElevatedButton.icon(
              onPressed: () => _showCouponForm(context, null),
              icon: const Icon(LucideIcons.plus),
              label: const Text('Create Coupon'),
            ),
          );
        }
        final coupon = coupons[index - 1];
        return _CouponCard(coupon: coupon);
      },
    );
  }
}

class _CouponCard extends StatelessWidget {
  final Map<String, dynamic> coupon;
  const _CouponCard({required this.coupon});

  Color _statusColor(String? status) {
    if (coupon['is_active'] == true) return AppColors.success;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final isActive = coupon['is_active'] == true;
    final code = coupon['code'] ?? '';
    final type = coupon['type'] ?? 'percentage';
    final value = (coupon['value'] ?? 0).toDouble();
    final used = (coupon['used_count'] ?? 0).toInt();
    final limit = (coupon['usage_limit'] ?? 0).toInt();
    final validFrom = coupon['valid_from'] ?? '';
    final validTo = coupon['valid_to'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: AppColors.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: AppColors.border)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(code, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'monospace')),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _statusColor(null).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(isActive ? 'Active' : 'Inactive', style: TextStyle(fontSize: 12, color: _statusColor(null))),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              type == 'percentage' ? '${value.toStringAsFixed(0)}% OFF' : '₹${value.toStringAsFixed(2)} OFF',
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            Text('Used: $used / ${limit > 0 ? limit.toString() : "∞"}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            if (validFrom != null && validTo != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text('$validFrom → $validTo', style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(LucideIcons.edit, size: 16),
                  label: const Text('Edit'),
                  onPressed: () => _showCouponForm(context, coupon),
                ),
                const SizedBox(width: 4),
                TextButton.icon(
                  icon: const Icon(LucideIcons.trash2, size: 16),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(foregroundColor: AppColors.error),
                  onPressed: () => _confirmDelete(context, coupon['id']),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

void _showCouponForm(BuildContext context, Map<String, dynamic>? existing) {
  final codeCtrl = TextEditingController(text: existing?['code'] ?? '');
  final descCtrl = TextEditingController(text: existing?['description'] ?? '');
  final valueCtrl = TextEditingController(text: existing != null ? (existing['value'] ?? 0).toString() : '');
  final minOrderCtrl = TextEditingController(text: existing != null ? (existing['min_order_amount'] ?? 0).toString() : '');
  final maxDiscCtrl = TextEditingController(text: existing != null ? (existing['max_discount'] ?? 0).toString() : '');
  final usageLimitCtrl = TextEditingController(text: existing != null ? (existing['usage_limit'] ?? 0).toString() : '');
  String type = existing?['type'] ?? 'percentage';
  bool isActive = existing?['is_active'] ?? true;
  final isEditing = existing != null;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.cardBg,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20, right: 20, top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(isEditing ? 'Edit Coupon' : 'Create Coupon', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Code', border: OutlineInputBorder()), textCapitalization: TextCapitalization.characters),
                  const SizedBox(height: 8),
                  TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()), maxLines: 2),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: type,
                    decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'percentage', child: Text('Percentage')),
                      DropdownMenuItem(value: 'fixed', child: Text('Fixed Amount')),
                      DropdownMenuItem(value: 'free_shipping', child: Text('Free Shipping')),
                    ],
                    onChanged: (v) => setSheetState(() => type = v!),
                  ),
                  const SizedBox(height: 8),
                  TextField(controller: valueCtrl, decoration: const InputDecoration(labelText: 'Value', border: OutlineInputBorder()), keyboardType: TextInputType.number),
                  const SizedBox(height: 8),
                  TextField(controller: minOrderCtrl, decoration: const InputDecoration(labelText: 'Min Order Amount', border: OutlineInputBorder()), keyboardType: TextInputType.number),
                  const SizedBox(height: 8),
                  TextField(controller: maxDiscCtrl, decoration: const InputDecoration(labelText: 'Max Discount', border: OutlineInputBorder()), keyboardType: TextInputType.number),
                  const SizedBox(height: 8),
                  TextField(controller: usageLimitCtrl, decoration: const InputDecoration(labelText: 'Usage Limit (0 = unlimited)', border: OutlineInputBorder()), keyboardType: TextInputType.number),
                  const SizedBox(height: 8),
                  if (isEditing)
                    SwitchListTile(
                      title: const Text('Active'),
                      value: isActive,
                      onChanged: (v) => setSheetState(() => isActive = v),
                    ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      final data = <String, dynamic>{
                        'code': codeCtrl.text,
                        'description': descCtrl.text,
                        'type': type,
                        'value': double.tryParse(valueCtrl.text) ?? 0,
                        'min_order_amount': double.tryParse(minOrderCtrl.text) ?? 0,
                        'max_discount': double.tryParse(maxDiscCtrl.text) ?? 0,
                        'usage_limit': int.tryParse(usageLimitCtrl.text) ?? 0,
                      };
                      if (isEditing) {
                        data['is_active'] = isActive;
                        context.read<AdminPromotionsBloc>().add(UpdateCoupon(existing['id'], data));
                      } else {
                        context.read<AdminPromotionsBloc>().add(CreateCoupon(data));
                      }
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                    child: Text(isEditing ? 'Update Coupon' : 'Create Coupon'),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

void _confirmDelete(BuildContext context, String id) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.cardBg,
      title: const Text('Delete Coupon'),
      content: const Text('Are you sure you want to delete this coupon?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        TextButton(
          onPressed: () {
            context.read<AdminPromotionsBloc>().add(DeleteCoupon(id));
            Navigator.pop(ctx);
          },
          style: TextButton.styleFrom(foregroundColor: AppColors.error),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
}

class _FeaturedListingsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminPromotionsBloc, AdminPromotionsState>(
      builder: (context, state) {
        if (state is AdminPromotionsLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is AdminPromotionsError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(state.message, style: const TextStyle(color: AppColors.error)),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => context.read<AdminPromotionsBloc>().add(const LoadFeaturedListings()),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        if (state is FeaturedListingsLoaded) {
          return _FeaturedListView(listings: state.listings);
        }
        return const Center(child: Text('Tap refresh to load featured listings'));
      },
    );
  }
}

class _FeaturedListView extends StatelessWidget {
  final List<dynamic> listings;
  const _FeaturedListView({required this.listings});

  @override
  Widget build(BuildContext context) {
    if (listings.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.star, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No featured listings', style: TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: listings.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ElevatedButton.icon(
              onPressed: () => _showFeaturedForm(context, null),
              icon: const Icon(LucideIcons.plus),
              label: const Text('Add Featured Listing'),
            ),
          );
        }
        final listing = listings[index - 1];
        return _FeaturedCard(listing: listing);
      },
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  final Map<String, dynamic> listing;
  const _FeaturedCard({required this.listing});

  @override
  Widget build(BuildContext context) {
    final priority = listing['priority'] ?? 0;
    final startDate = listing['start_date'] ?? '';
    final endDate = listing['end_date'] ?? '';
    final fee = (listing['fee'] ?? 0).toDouble();
    final status = listing['status'] ?? 'active';
    final productId = listing['product_id'];
    final barberId = listing['barber_id'];
    final vendorId = listing['vendor_id'];

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: AppColors.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: AppColors.border)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('Priority: $priority', style: const TextStyle(fontSize: 12, color: AppColors.primary)),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: status == 'active' ? AppColors.success.withValues(alpha: 0.15) : Colors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(status.toUpperCase(), style: TextStyle(fontSize: 11, color: status == 'active' ? AppColors.success : Colors.orange)),
                ),
                const Spacer(),
                Text('Fee: ₹${fee.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 6),
            if (productId != null) Text('Product: $productId', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            if (barberId != null) Text('Barber: $barberId', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            if (vendorId != null) Text('Vendor: $vendorId', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 4),
            Text('$startDate → $endDate', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(LucideIcons.trash2, size: 16),
                  label: const Text('Remove'),
                  style: TextButton.styleFrom(foregroundColor: AppColors.error),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: AppColors.cardBg,
                        title: const Text('Remove Listing'),
                        content: const Text('Are you sure?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                          TextButton(
                            onPressed: () {
                              context.read<AdminPromotionsBloc>().add(DeleteFeaturedListing(listing['id']));
                              Navigator.pop(ctx);
                            },
                            style: TextButton.styleFrom(foregroundColor: AppColors.error),
                            child: const Text('Remove'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

void _showFeaturedForm(BuildContext context, Map<String, dynamic>? existing) {
  final barberIdCtrl = TextEditingController(text: existing?['barber_id'] ?? '');
  final vendorIdCtrl = TextEditingController(text: existing?['vendor_id'] ?? '');
  final productIdCtrl = TextEditingController(text: existing?['product_id'] ?? '');
  final startDateCtrl = TextEditingController(text: existing?['start_date'] ?? '');
  final endDateCtrl = TextEditingController(text: existing?['end_date'] ?? '');
  final feeCtrl = TextEditingController(text: existing != null ? (existing['fee'] ?? 0).toString() : '0');
  final priorityCtrl = TextEditingController(text: existing != null ? (existing['priority'] ?? 0).toString() : '0');

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.cardBg,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Add Featured Listing', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(controller: barberIdCtrl, decoration: const InputDecoration(labelText: 'Barber ID (optional)', border: OutlineInputBorder())),
              const SizedBox(height: 8),
              TextField(controller: vendorIdCtrl, decoration: const InputDecoration(labelText: 'Vendor ID (optional)', border: OutlineInputBorder())),
              const SizedBox(height: 8),
              TextField(controller: productIdCtrl, decoration: const InputDecoration(labelText: 'Product ID (optional)', border: OutlineInputBorder())),
              const SizedBox(height: 8),
              TextField(controller: startDateCtrl, decoration: const InputDecoration(labelText: 'Start Date (YYYY-MM-DD)', border: OutlineInputBorder())),
              const SizedBox(height: 8),
              TextField(controller: endDateCtrl, decoration: const InputDecoration(labelText: 'End Date (YYYY-MM-DD)', border: OutlineInputBorder())),
              const SizedBox(height: 8),
              TextField(controller: feeCtrl, decoration: const InputDecoration(labelText: 'Fee', border: OutlineInputBorder()), keyboardType: TextInputType.number),
              const SizedBox(height: 8),
              TextField(controller: priorityCtrl, decoration: const InputDecoration(labelText: 'Priority', border: OutlineInputBorder()), keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  final data = <String, dynamic>{
                    if (barberIdCtrl.text.isNotEmpty) 'barber_id': barberIdCtrl.text,
                    if (vendorIdCtrl.text.isNotEmpty) 'vendor_id': vendorIdCtrl.text,
                    if (productIdCtrl.text.isNotEmpty) 'product_id': productIdCtrl.text,
                    'start_date': startDateCtrl.text,
                    'end_date': endDateCtrl.text,
                    'fee': double.tryParse(feeCtrl.text) ?? 0,
                    'priority': int.tryParse(priorityCtrl.text) ?? 0,
                  };
                  context.read<AdminPromotionsBloc>().add(CreateFeaturedListing(data));
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                child: const Text('Create Listing'),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _NotificationTemplatesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminPromotionsBloc, AdminPromotionsState>(
      builder: (context, state) {
        if (state is AdminPromotionsLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is AdminPromotionsError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(state.message, style: const TextStyle(color: AppColors.error)),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => context.read<AdminPromotionsBloc>().add(const LoadNotificationTemplates()),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        if (state is NotificationTemplatesLoaded) {
          return _TemplateListView(templates: state.templates);
        }
        return const Center(child: Text('Tap refresh to load templates'));
      },
    );
  }
}

class _TemplateListView extends StatelessWidget {
  final List<dynamic> templates;
  const _TemplateListView({required this.templates});

  @override
  Widget build(BuildContext context) {
    if (templates.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.mail, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No notification templates', style: TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: templates.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ElevatedButton.icon(
              onPressed: () => _showTemplateForm(context, null),
              icon: const Icon(LucideIcons.plus),
              label: const Text('Create Template'),
            ),
          );
        }
        final template = templates[index - 1];
        return _TemplateCard(template: template);
      },
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final Map<String, dynamic> template;
  const _TemplateCard({required this.template});

  @override
  Widget build(BuildContext context) {
    final name = template['name'] ?? '';
    final title = template['title'] ?? '';
    final type = template['type'] ?? '';
    final channel = template['channel'] ?? 'all';
    final isActive = template['is_active'] == true;
    final body = template['body'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: AppColors.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: AppColors.border)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.success.withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(isActive ? 'Active' : 'Inactive', style: TextStyle(fontSize: 11, color: isActive ? AppColors.success : Colors.grey)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                  child: Text(type, style: const TextStyle(fontSize: 10, color: AppColors.primary)),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                  child: Text(channel, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                ),
              ],
            ),
            if (body.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(body, style: const TextStyle(fontSize: 12, color: Colors.grey), maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(LucideIcons.eye, size: 16),
                  label: const Text('Preview'),
                  onPressed: () => _showTemplatePreview(context, template),
                ),
                const SizedBox(width: 4),
                TextButton.icon(
                  icon: const Icon(LucideIcons.edit, size: 16),
                  label: const Text('Edit'),
                  onPressed: () => _showTemplateForm(context, template),
                ),
                const SizedBox(width: 4),
                TextButton.icon(
                  icon: const Icon(LucideIcons.trash2, size: 16),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(foregroundColor: AppColors.error),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: AppColors.cardBg,
                        title: const Text('Delete Template'),
                        content: const Text('Are you sure?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                          TextButton(
                            onPressed: () {
                              context.read<AdminPromotionsBloc>().add(DeleteNotificationTemplate(template['id']));
                              Navigator.pop(ctx);
                            },
                            style: TextButton.styleFrom(foregroundColor: AppColors.error),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

void _showTemplatePreview(BuildContext context, Map<String, dynamic> template) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.cardBg,
      title: Text(template['name'] ?? 'Template Preview'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Title: ${template['title'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            width: double.maxFinite,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(template['body'] ?? ''),
          ),
          const SizedBox(height: 8),
          Text('Type: ${template['type'] ?? ''}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text('Channel: ${template['channel'] ?? 'all'}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          if (template['variables'] != null) ...[
            const SizedBox(height: 8),
            Text('Variables: ${template['variables']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
      ],
    ),
  );
}

void _showTemplateForm(BuildContext context, Map<String, dynamic>? existing) {
  final nameCtrl = TextEditingController(text: existing?['name'] ?? '');
  final titleCtrl = TextEditingController(text: existing?['title'] ?? '');
  final bodyCtrl = TextEditingController(text: existing?['body'] ?? '');
  final typeCtrl = TextEditingController(text: existing?['type'] ?? '');
  final channelCtrl = TextEditingController(text: existing?['channel'] ?? 'all');
  bool isActive = existing?['is_active'] ?? true;
  final isEditing = existing != null;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.cardBg,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20, right: 20, top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(isEditing ? 'Edit Template' : 'Create Template', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder())),
                  const SizedBox(height: 8),
                  TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder())),
                  const SizedBox(height: 8),
                  TextField(controller: bodyCtrl, decoration: const InputDecoration(labelText: 'Body', border: OutlineInputBorder()), maxLines: 4),
                  const SizedBox(height: 8),
                  TextField(controller: typeCtrl, decoration: const InputDecoration(labelText: 'Type (e.g. order_confirmation, promotion)', border: OutlineInputBorder())),
                  const SizedBox(height: 8),
                  TextField(controller: channelCtrl, decoration: const InputDecoration(labelText: 'Channel (all, email, push, sms)', border: OutlineInputBorder())),
                  const SizedBox(height: 8),
                  if (isEditing)
                    SwitchListTile(
                      title: const Text('Active'),
                      value: isActive,
                      onChanged: (v) => setSheetState(() => isActive = v),
                    ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      final data = <String, dynamic>{
                        'name': nameCtrl.text,
                        'title': titleCtrl.text,
                        'body': bodyCtrl.text,
                        'type': typeCtrl.text,
                        'channel': channelCtrl.text,
                      };
                      if (isEditing) {
                        data['is_active'] = isActive;
                        context.read<AdminPromotionsBloc>().add(UpdateNotificationTemplate(existing['id'], data));
                      } else {
                        context.read<AdminPromotionsBloc>().add(CreateNotificationTemplate(data));
                      }
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                    child: Text(isEditing ? 'Update Template' : 'Create Template'),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
