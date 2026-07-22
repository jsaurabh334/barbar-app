import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:barbar_app/core/theme/app_theme.dart';
import 'package:barbar_app/data/models/vendor_model.dart';
import 'package:barbar_app/presentation/bloc/admin/admin_vendors_bloc.dart';
import 'package:barbar_app/domain/repositories/admin_repository.dart';
import 'package:barbar_app/presentation/widgets/admin/admin_status_badge.dart';
import 'package:barbar_app/presentation/widgets/admin/admin_detail_card.dart';


class AdminVendorDetailScreen extends StatefulWidget {
  final VendorModel vendor;
  const AdminVendorDetailScreen({super.key, required this.vendor});
  @override
  State<AdminVendorDetailScreen> createState() => _AdminVendorDetailScreenState();
}

class _AdminVendorDetailScreenState extends State<AdminVendorDetailScreen> {
  List<dynamic> _documents = [];
  bool _loadingDocs = true;
  String? _docError;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    setState(() { _loadingDocs = true; _docError = null; });
    try {
      final docs = await context.read<AdminRepository>().getVendorDocuments(widget.vendor.id);
      if (mounted) setState(() { _documents = docs; _loadingDocs = false; });
    } catch (e) {
      if (mounted) setState(() { _docError = e.toString(); _loadingDocs = false; });
    }
  }

  void _showActionSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.vendor;
    return BlocListener<AdminVendorsBloc, AdminVendorsState>(
      listener: (ctx, state) {
        if (state is AdminVendorsActionSuccess) {
          _showActionSnackbar(state.message);
        } else if (state is AdminVendorsError) {
          _showActionSnackbar(state.message);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(v.businessName),
          actions: [
            IconButton(
              icon: Icon(v.isFeatured ? LucideIcons.star : LucideIcons.star, color: v.isFeatured ? Colors.amber : null),
              tooltip: v.isFeatured ? 'Unfeature' : 'Feature',
              onPressed: () => context.read<AdminVendorsBloc>().add(ToggleVendorFeatured(v.id, !v.isFeatured)),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(v),
              const SizedBox(height: 16),
              _buildSection('Business Info', [
                AdminDetailCard(label: 'Email', value: v.businessEmail ?? '-', icon: LucideIcons.mail),
                AdminDetailCard(label: 'Phone', value: v.businessPhone ?? '-', icon: LucideIcons.phone),
                AdminDetailCard(label: 'Address', value: '${v.address ?? ""}, ${v.city ?? ""}, ${v.state ?? ""}', icon: LucideIcons.mapPin),
                AdminDetailCard(label: 'Pincode', value: v.pincode ?? '-', icon: LucideIcons.map),
                if (v.gstNumber != null) AdminDetailCard(label: 'GST', value: v.gstNumber!, icon: LucideIcons.fileText),
                if (v.panNumber != null) AdminDetailCard(label: 'PAN', value: v.panNumber!, icon: LucideIcons.fileText),
                if (v.website != null) AdminDetailCard(label: 'Website', value: v.website!, icon: LucideIcons.globe),
                if (v.businessType != null) AdminDetailCard(label: 'Type', value: v.businessType!, icon: LucideIcons.tag),
              ]),
              const SizedBox(height: 12),
              _buildSection('Performance', [
                AdminDetailCard(label: 'Rating', value: v.rating.toStringAsFixed(1), icon: LucideIcons.star, trailing: Text('${v.reviewCount} reviews', style: const TextStyle(fontSize: 12, color: Colors.grey))),
                AdminDetailCard(label: 'Total Products', value: v.totalProducts.toString(), icon: LucideIcons.package),
                AdminDetailCard(label: 'Total Orders', value: v.totalOrders.toString(), icon: LucideIcons.shoppingCart),
                AdminDetailCard(label: 'Total Revenue', value: '₹${v.totalRevenue.toStringAsFixed(0)}', icon: LucideIcons.trendingUp),
                AdminDetailCard(label: 'Commission Rate', value: '${v.commissionRate.toStringAsFixed(1)}%', icon: LucideIcons.percent),
              ]),
              const SizedBox(height: 12),
              _buildSection('Documents & KYC', [
                AdminDetailCard(label: 'KYC Status', value: v.kycStatus.toUpperCase(), icon: LucideIcons.shield, trailing: AdminStatusBadge(label: v.kycStatus)),
                AdminDetailCard(label: 'Verified', value: v.isVerified ? 'Yes' : 'No', icon: LucideIcons.checkCircle),
                const SizedBox(height: 8),
                if (_loadingDocs)
                  const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
                else if (_docError != null)
                  _ErrorRetry(message: _docError!, onRetry: _loadDocuments)
                else if (_documents.isEmpty)
                  const Padding(padding: EdgeInsets.all(16), child: Text('No documents uploaded', style: TextStyle(color: Colors.grey)))
                else
                  ..._documents.map((doc) => _DocumentCard(document: doc, context: context)),
              ]),
              const SizedBox(height: 12),
              _buildSection('Details', [
                if (v.deliveryTimeframe != null) AdminDetailCard(label: 'Delivery Timeframe', value: v.deliveryTimeframe!, icon: LucideIcons.truck),
                if (v.createdAt != null) AdminDetailCard(label: 'Registered', value: v.createdAt!.substring(0, 10), icon: LucideIcons.calendar),
                AdminDetailCard(label: 'Active', value: v.isActive ? 'Yes' : 'No', icon: LucideIcons.activity, trailing: AdminStatusBadge(label: v.isActive ? 'active' : 'inactive')),
              ]),
              const SizedBox(height: 12),
              _buildActions(v),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(VendorModel v) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: v.logo != null ? Colors.transparent : AppColors.primary.withValues(alpha: 0.2),
            backgroundImage: v.logo != null ? NetworkImage(v.logo!) : null,
            child: v.logo == null ? const Icon(LucideIcons.store, size: 40, color: AppColors.primary) : null,
          ),
          const SizedBox(height: 12),
          Text(v.businessName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          if (v.businessDescription != null && v.businessDescription!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(v.businessDescription!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13), textAlign: TextAlign.center),
            ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AdminStatusBadge(label: v.status),
              const SizedBox(width: 8),
              AdminStatusBadge(label: v.kycStatus),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1, color: AppColors.primary)),
        ),
        ...children,
      ],
    );
  }

  Widget _buildActions(VendorModel v) {
    final bloc = context.read<AdminVendorsBloc>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('ACTIONS', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1, color: AppColors.primary)),
        const SizedBox(height: 8),
        if (v.status == 'pending' || v.status == 'suspended')
          ElevatedButton.icon(
            onPressed: () => bloc.add(ApproveVendor(v.id)),
            icon: const Icon(LucideIcons.checkCircle),
            label: const Text('Approve Vendor'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white),
          ),
        if (v.status != 'suspended' && v.status != 'rejected')
          ElevatedButton.icon(
            onPressed: () => _showStatusDialog(context, v, 'suspend'),
            icon: const Icon(LucideIcons.ban),
            label: const Text('Suspend Vendor'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
          ),
        if (v.status != 'rejected')
          OutlinedButton.icon(
            onPressed: () => _showStatusDialog(context, v, 'reject'),
            icon: const Icon(LucideIcons.xCircle, color: AppColors.error),
            label: const Text('Reject Vendor', style: TextStyle(color: AppColors.error)),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.error)),
          ),
        if (v.status == 'suspended')
          OutlinedButton.icon(
            onPressed: () => bloc.add(ReactivateVendor(v.id)),
            icon: const Icon(LucideIcons.refreshCw, color: AppColors.success),
            label: const Text('Reactivate Vendor', style: TextStyle(color: AppColors.success)),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.success)),
          ),
      ].map((btn) => Padding(padding: const EdgeInsets.only(bottom: 8), child: btn)).toList(),
    );
  }

  void _showStatusDialog(BuildContext context, VendorModel v, String action) {
    final remarksCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: Text('${action[0].toUpperCase()}${action.substring(1)} Vendor'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Are you sure you want to $action ${v.businessName}?'),
            const SizedBox(height: 12),
            TextField(
              controller: remarksCtrl,
              decoration: const InputDecoration(labelText: 'Remarks (optional)', border: OutlineInputBorder()),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: action == 'suspend' ? AppColors.error : AppColors.error),
            onPressed: () {
              Navigator.pop(ctx);
              final remarks = remarksCtrl.text.trim();
              if (action == 'suspend') {
                context.read<AdminVendorsBloc>().add(SuspendVendor(v.id));
              } else {
                context.read<AdminVendorsBloc>().add(RejectVendor(v.id, remarks: remarks.isNotEmpty ? remarks : null));
              }
            },
            child: Text(action[0].toUpperCase() + action.substring(1)),
          ),
        ],
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final Map<String, dynamic> document;
  final BuildContext context;

  const _DocumentCard({required this.document, required this.context});

  @override
  Widget build(BuildContext ctx) {
    final docType = document['doc_type'] ?? 'Unknown';
    final docNumber = document['doc_number'] ?? '';
    final docUrl = document['doc_url'] ?? '';
    final status = document['status'] ?? 'pending';
    final remarks = document['remarks'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.fileText, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Expanded(child: Text(docType, style: const TextStyle(fontWeight: FontWeight.bold))),
              AdminStatusBadge(label: status),
            ],
          ),
          if (docNumber.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text(docNumber, style: const TextStyle(fontSize: 12, color: Colors.grey))),
          if (remarks.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 2), child: Text('Remarks: $remarks', style: const TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic))),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (status == 'pending') ...[
                TextButton.icon(
                  icon: const Icon(LucideIcons.check, size: 16),
                  label: const Text('Approve'),
                  style: TextButton.styleFrom(foregroundColor: AppColors.success),
                  onPressed: () => context.read<AdminRepository>().verifyVendorDocument(document['id'], 'approved'),
                ),
                TextButton.icon(
                  icon: const Icon(LucideIcons.x, size: 16),
                  label: const Text('Reject'),
                  style: TextButton.styleFrom(foregroundColor: AppColors.error),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (dCtx) => AlertDialog(
                        backgroundColor: AppColors.cardBg,
                        title: const Text('Reject Document'),
                        content: const Text('Are you sure?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('Cancel')),
                          TextButton(
                            onPressed: () {
                              context.read<AdminRepository>().verifyVendorDocument(document['id'], 'rejected');
                              Navigator.pop(dCtx);
                            },
                            style: TextButton.styleFrom(foregroundColor: AppColors.error),
                            child: const Text('Reject'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
              if (docUrl.isNotEmpty)
                TextButton.icon(
                  icon: const Icon(LucideIcons.externalLink, size: 16),
                  label: const Text('View'),
                  onPressed: () {
                    // Open URL — placeholder
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Document URL: $docUrl')));
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorRetry({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(child: Text(message, style: const TextStyle(color: AppColors.error, fontSize: 12))),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
