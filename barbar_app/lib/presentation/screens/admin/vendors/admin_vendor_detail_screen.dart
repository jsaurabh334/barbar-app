import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:barbar_app/core/theme/app_theme.dart';
import 'package:barbar_app/data/models/vendor_model.dart';
import 'package:barbar_app/presentation/bloc/admin/admin_vendors_bloc.dart';
import 'package:barbar_app/domain/repositories/admin_repository.dart';
import 'package:barbar_app/presentation/widgets/admin/admin_status_badge.dart';
import 'package:url_launcher/url_launcher.dart';

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
    setState(() {
      _loadingDocs = true;
      _docError = null;
    });
    try {
      final docs = await context.read<AdminRepository>().getVendorDocuments(widget.vendor.id);
      if (mounted) setState(() { _documents = docs; _loadingDocs = false; });
    } catch (e) {
      if (mounted) setState(() { _docError = e.toString(); _loadingDocs = false; });
    }
  }

  void _showActionSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
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
        backgroundColor: const Color(0xFF0F0F15),
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.black),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            v.businessName,
            style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          actions: [
            IconButton(
              icon: Icon(v.isFeatured ? LucideIcons.star : LucideIcons.star, color: v.isFeatured ? Colors.orange.shade900 : Colors.black87),
              tooltip: v.isFeatured ? 'Unfeature' : 'Feature',
              onPressed: () => context.read<AdminVendorsBloc>().add(ToggleVendorFeatured(v.id, !v.isFeatured)),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Glassmorphic Header Card ---
              _buildGlassHeader(v),
              const SizedBox(height: 16),

              // --- Performance Grid ---
              _buildPerformanceMetrics(v),
              const SizedBox(height: 16),

              // --- Business Info Card ---
              _buildSectionCard(
                title: 'Business Information',
                icon: LucideIcons.building,
                child: Column(
                  children: [
                    _buildDetailItem(LucideIcons.mail, 'Email', v.businessEmail ?? '-'),
                    const Divider(color: Colors.white10, height: 16),
                    _buildDetailItem(LucideIcons.phone, 'Phone', v.businessPhone ?? '-'),
                    const Divider(color: Colors.white10, height: 16),
                    _buildDetailItem(LucideIcons.mapPin, 'Address', '${v.address ?? ""}, ${v.city ?? ""}, ${v.state ?? ""}'),
                    const Divider(color: Colors.white10, height: 16),
                    _buildDetailItem(LucideIcons.map, 'Pincode', v.pincode ?? '-'),
                    if (v.gstNumber != null && v.gstNumber!.isNotEmpty) ...[
                      const Divider(color: Colors.white10, height: 16),
                      _buildDetailItem(LucideIcons.fileText, 'GST Number', v.gstNumber!),
                    ],
                    if (v.panNumber != null && v.panNumber!.isNotEmpty) ...[
                      const Divider(color: Colors.white10, height: 16),
                      _buildDetailItem(LucideIcons.fileText, 'PAN Number', v.panNumber!),
                    ],
                    if (v.website != null && v.website!.isNotEmpty) ...[
                      const Divider(color: Colors.white10, height: 16),
                      _buildDetailItem(LucideIcons.globe, 'Website', v.website!),
                    ],
                    if (v.businessType != null && v.businessType!.isNotEmpty) ...[
                      const Divider(color: Colors.white10, height: 16),
                      _buildDetailItem(LucideIcons.tag, 'Business Type', v.businessType!),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // --- Documents & KYC Section ---
              _buildSectionCard(
                title: 'Documents & KYC',
                icon: LucideIcons.shieldCheck,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(LucideIcons.checkCircle, size: 16, color: Colors.white54),
                            const SizedBox(width: 8),
                            Text('Verification Status', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13)),
                          ],
                        ),
                        AdminStatusBadge(label: v.kycStatus),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_loadingDocs)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
                      )
                    else if (_docError != null)
                      _ErrorRetry(message: _docError!, onRetry: _loadDocuments)
                    else if (_documents.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text('No documents uploaded.', style: GoogleFonts.outfit(color: Colors.white54, fontSize: 13)),
                      )
                    else
                      ..._documents.map((doc) => _DocumentCard(document: doc, context: context)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // --- Extra Info Card ---
              _buildSectionCard(
                title: 'Vendor Details',
                icon: LucideIcons.info,
                child: Column(
                  children: [
                    if (v.deliveryTimeframe != null && v.deliveryTimeframe!.isNotEmpty)
                      _buildDetailItem(LucideIcons.truck, 'Delivery Timeframe', v.deliveryTimeframe!),
                    if (v.createdAt != null) ...[
                      if (v.deliveryTimeframe != null && v.deliveryTimeframe!.isNotEmpty)
                        const Divider(color: Colors.white10, height: 16),
                      _buildDetailItem(LucideIcons.calendar, 'Registered On', v.createdAt!.substring(0, 10)),
                    ],
                    const Divider(color: Colors.white10, height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(LucideIcons.activity, size: 16, color: Colors.white54),
                            const SizedBox(width: 8),
                            Text('Account Active', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13)),
                          ],
                        ),
                        AdminStatusBadge(label: v.isActive ? 'active' : 'inactive'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // --- Action Buttons ---
              _buildActions(v),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassHeader(VendorModel v) {
    final statusColor = v.status == 'approved'
        ? Colors.greenAccent
        : (v.status == 'pending' ? Colors.orangeAccent : Colors.redAccent);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1E2E), Color(0xFF141420)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          if (v.banner != null && v.banner!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                v.banner!,
                height: 110,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          if (v.banner != null && v.banner!.isNotEmpty) const SizedBox(height: 14),
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 2),
                ),
                child: CircleAvatar(
                  radius: 36,
                  backgroundColor: const Color(0xFF2B2B3D),
                  backgroundImage: (v.logo != null && v.logo!.isNotEmpty) ? NetworkImage(v.logo!) : null,
                  child: (v.logo == null || v.logo!.isEmpty)
                      ? const Icon(LucideIcons.store, size: 32, color: AppColors.primary)
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      v.businessName,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (v.businessDescription != null && v.businessDescription!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        v.businessDescription!,
                        style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: statusColor.withOpacity(0.5), width: 1),
                          ),
                          child: Text(
                            v.status.toUpperCase(),
                            style: GoogleFonts.outfit(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.amber.withOpacity(0.4)),
                          ),
                          child: Row(
                            children: [
                              const Icon(LucideIcons.star, size: 12, color: Colors.amber),
                              const SizedBox(width: 4),
                              Text(
                                v.rating.toStringAsFixed(1),
                                style: GoogleFonts.outfit(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetrics(VendorModel v) {
    return Row(
      children: [
        Expanded(child: _buildMetricTile("Products", v.totalProducts.toString(), LucideIcons.package)),
        const SizedBox(width: 10),
        Expanded(child: _buildMetricTile("Orders", v.totalOrders.toString(), LucideIcons.shoppingCart)),
        const SizedBox(width: 10),
        Expanded(child: _buildMetricTile("Revenue", "₹${v.totalRevenue.toStringAsFixed(0)}", LucideIcons.trendingUp)),
      ],
    );
  }

  Widget _buildMetricTile(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(height: 6),
          Text(value, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
          Text(label, style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.white54),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11)),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActions(VendorModel v) {
    final bloc = context.read<AdminVendorsBloc>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'ACTIONS',
          style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppColors.primary),
        ),
        const SizedBox(height: 10),
        if (v.status == 'pending' || v.status == 'suspended')
          ElevatedButton.icon(
            onPressed: () => bloc.add(ApproveVendor(v.id)),
            icon: const Icon(LucideIcons.checkCircle, color: Colors.white),
            label: Text('APPROVE VENDOR', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        if (v.status != 'suspended' && v.status != 'rejected')
          ElevatedButton.icon(
            onPressed: () => _showStatusDialog(context, v, 'suspend'),
            icon: const Icon(LucideIcons.ban, color: Colors.black),
            label: Text('SUSPEND VENDOR', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orangeAccent,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        if (v.status != 'rejected') ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _showStatusDialog(context, v, 'reject'),
            icon: const Icon(LucideIcons.xCircle, color: Colors.redAccent),
            label: Text('REJECT VENDOR', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.redAccent)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.redAccent, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
        if (v.status == 'suspended') ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => bloc.add(ReactivateVendor(v.id)),
            icon: const Icon(LucideIcons.refreshCw, color: Colors.greenAccent),
            label: Text('REACTIVATE VENDOR', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.greenAccent)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.greenAccent, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ],
    );
  }

  void _showStatusDialog(BuildContext context, VendorModel v, String action) {
    final remarksCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('${action[0].toUpperCase()}${action.substring(1)} Vendor', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to $action ${v.businessName}?', style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 12),
            TextField(
              controller: remarksCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Remarks (optional)',
                labelStyle: const TextStyle(color: Colors.white70),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white24)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary)),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.white60))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: action == 'suspend' ? Colors.orangeAccent : Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              final remarks = remarksCtrl.text.trim();
              if (action == 'suspend') {
                context.read<AdminVendorsBloc>().add(SuspendVendor(v.id));
              } else {
                context.read<AdminVendorsBloc>().add(RejectVendor(v.id, remarks: remarks.isNotEmpty ? remarks : null));
              }
            },
            child: Text(action[0].toUpperCase() + action.substring(1), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
        color: const Color(0xFF141420),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.fileText, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(child: Text(docType, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold))),
              AdminStatusBadge(label: status),
            ],
          ),
          if (docNumber.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text(docNumber, style: GoogleFonts.outfit(fontSize: 12, color: Colors.white54))),
          if (remarks.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 2), child: Text('Remarks: $remarks', style: GoogleFonts.outfit(fontSize: 11, color: Colors.redAccent))),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (status == 'pending') ...[
                TextButton.icon(
                  icon: const Icon(LucideIcons.check, size: 16),
                  label: const Text('Approve'),
                  style: TextButton.styleFrom(foregroundColor: Colors.green),
                  onPressed: () => context.read<AdminRepository>().verifyVendorDocument(document['id'], 'approved'),
                ),
                TextButton.icon(
                  icon: const Icon(LucideIcons.x, size: 16),
                  label: const Text('Reject'),
                  style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (dCtx) => AlertDialog(
                        backgroundColor: const Color(0xFF1E1E2E),
                        title: Text('Reject Document', style: GoogleFonts.outfit(color: Colors.white)),
                        content: Text('Are you sure you want to reject this document?', style: GoogleFonts.outfit(color: Colors.white70)),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('Cancel', style: TextStyle(color: Colors.white60))),
                          TextButton(
                            onPressed: () {
                              context.read<AdminRepository>().verifyVendorDocument(document['id'], 'rejected');
                              Navigator.pop(dCtx);
                            },
                            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
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
                  style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                  onPressed: () async {
                    final uri = Uri.parse(docUrl);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
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
          Expanded(child: Text(message, style: GoogleFonts.outfit(color: Colors.redAccent, fontSize: 12))),
          TextButton(onPressed: onRetry, child: Text('Retry', style: GoogleFonts.outfit(color: AppColors.primary))),
        ],
      ),
    );
  }
}
