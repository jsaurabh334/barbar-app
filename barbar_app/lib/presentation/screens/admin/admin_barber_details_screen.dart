import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:barbar_app/presentation/bloc/admin/admin_barber_details_bloc.dart';
import 'package:barbar_app/domain/repositories/admin_repository.dart';
import 'package:intl/intl.dart';
import 'package:barbar_app/core/utils/status_helper.dart';
import 'package:barbar_app/core/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminBarberDetailsScreen extends StatelessWidget {
  final String barberId;

  const AdminBarberDetailsScreen({Key? key, required this.barberId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AdminBarberDetailsBloc(
        adminRepository: context.read<AdminRepository>(),
      )..add(LoadBarberDetails(barberId)),
      child: const _BarberDetailsView(),
    );
  }
}

class _BarberDetailsView extends StatefulWidget {
  const _BarberDetailsView({Key? key}) : super(key: key);

  @override
  State<_BarberDetailsView> createState() => _BarberDetailsViewState();
}

class _BarberDetailsViewState extends State<_BarberDetailsView> {
  void _showRejectDialog(BuildContext context, String barberId) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Reject Application', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: reasonController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Reason for rejection',
            labelStyle: const TextStyle(color: Colors.white70),
            hintText: 'e.g. Invalid shop license, blurred photos',
            hintStyle: const TextStyle(color: Colors.white30),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white24)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary)),
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              context.read<AdminBarberDetailsBloc>().add(
                    RejectBarberDetailsEvent(barberId, reasonController.text.trim()),
                  );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Reject', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showKycRejectDialog(BuildContext context, String documentId) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Reject Document', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: reasonController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Rejection Reason',
            labelStyle: const TextStyle(color: Colors.white70),
            hintText: 'e.g. Image blurry, name mismatch',
            hintStyle: const TextStyle(color: Colors.white30),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white24)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary)),
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              context.read<AdminBarberDetailsBloc>().add(
                    RejectKycDocumentEvent(documentId, reasonController.text.trim()),
                  );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Reject', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showBarberDocRejectDialog(BuildContext context, String documentId) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Reject Document', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: reasonController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Rejection Reason',
            labelStyle: const TextStyle(color: Colors.white70),
            hintText: 'e.g. Image blurry, name mismatch',
            hintStyle: const TextStyle(color: Colors.white30),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white24)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary)),
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              context.read<AdminBarberDetailsBloc>().add(
                    RejectBarberDocumentEvent(documentId, reasonController.text.trim()),
                  );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Reject', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showImageViewer(BuildContext context, String url, String title) {
    double _rotation = 0;
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.black,
              insetPadding: EdgeInsets.zero,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: InteractiveViewer(
                      panEnabled: true,
                      minScale: 0.5,
                      maxScale: 4.0,
                      child: Transform.rotate(
                        angle: _rotation,
                        child: CachedNetworkImage(
                          imageUrl: url,
                          fit: BoxFit.contain,
                          placeholder: (_, __) => const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
                          errorWidget: (_, __, ___) => const Center(
                            child: Icon(LucideIcons.imageOff, color: Colors.white54, size: 50),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 40,
                    right: 20,
                    child: IconButton(
                      icon: const Icon(LucideIcons.x, color: Colors.white, size: 28),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ),
                  Positioned(
                    bottom: 40,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(LucideIcons.rotateCcw, color: Colors.white, size: 26),
                          onPressed: () {
                            setState(() => _rotation -= 1.5708);
                          },
                        ),
                        const SizedBox(width: 20),
                        IconButton(
                          icon: const Icon(LucideIcons.rotateCw, color: Colors.white, size: 26),
                          onPressed: () {
                            setState(() => _rotation += 1.5708);
                          },
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 40,
                    left: 20,
                    child: Text(
                      title,
                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showApproveDialog(BuildContext context, String barberId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Approve Barber Shop?', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('This shop will be approved and become active immediately on Barbar.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AdminBarberDetailsBloc>().add(ApproveBarberDetailsEvent(barberId));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Approve', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showSuspendDialog(BuildContext context, String barberId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Suspend Barber Shop?', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to suspend this barber? They will be hidden from customer search.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AdminBarberDetailsBloc>().add(SuspendBarberDetailsEvent(barberId));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Suspend', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F15),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F15),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Barber Details',
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: BlocConsumer<AdminBarberDetailsBloc, AdminBarberDetailsState>(
        listener: (context, state) {
          if (state is AdminBarberDetailsActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600)),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (state is AdminBarberDetailsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message, style: GoogleFonts.outfit(color: Colors.white)),
                backgroundColor: Colors.redAccent,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is AdminBarberDetailsLoading || state is AdminBarberDetailsInitial) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          if (state is AdminBarberDetailsLoaded) {
            final barber = state.barber;
            String submittedDate = "N/A";
            if (barber.createdAt != null) {
              final dt = DateTime.tryParse(barber.createdAt!);
              if (dt != null) {
                submittedDate = DateFormat('dd MMM yyyy').format(dt);
              }
            }

            final isApproved = StatusHelper.isApproved(barber.verificationStatus);
            final isPending = StatusHelper.isPending(barber.verificationStatus);
            final statusColor = isApproved
                ? Colors.greenAccent
                : (isPending ? Colors.orangeAccent : Colors.redAccent);

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Glassmorphic Header Card ---
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF1E1E2E),
                          const Color(0xFF141420),
                        ],
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
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.primary, width: 2),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(40),
                            child: (barber.fullShopImage != null && barber.fullShopImage!.isNotEmpty)
                                ? CachedNetworkImage(
                                    imageUrl: barber.fullShopImage!,
                                    width: 72,
                                    height: 72,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => Container(
                                      width: 72,
                                      height: 72,
                                      color: const Color(0xFF2B2B3D),
                                      child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
                                    ),
                                    errorWidget: (_, __, ___) => Container(
                                      width: 72,
                                      height: 72,
                                      color: const Color(0xFF2B2B3D),
                                      child: const Icon(LucideIcons.scissors, size: 36, color: AppColors.primary),
                                    ),
                                  )
                                : Container(
                                    width: 72,
                                    height: 72,
                                    color: const Color(0xFF2B2B3D),
                                    child: const Icon(LucideIcons.scissors, size: 36, color: AppColors.primary),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                barber.shopName,
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
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
                                      (barber.verificationStatus ?? 'pending').toUpperCase(),
                                      style: GoogleFonts.outfit(
                                        color: statusColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(LucideIcons.calendar, size: 13, color: Colors.white54),
                                  const SizedBox(width: 4),
                                  Text(
                                    submittedDate,
                                    style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // --- Owner Information ---
                  _buildSectionCard(
                    title: "Owner Information",
                    icon: LucideIcons.userCheck,
                    child: Column(
                      children: [
                        _buildDetailRow(LucideIcons.user, "Name", barber.ownerName ?? 'N/A'),
                        const Divider(color: Colors.white10, height: 16),
                        _buildDetailRow(LucideIcons.phone, "Phone", barber.phone ?? 'N/A'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // --- Shop Information & Location ---
                  _buildSectionCard(
                    title: "Shop & Location",
                    icon: LucideIcons.mapPin,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow(LucideIcons.navigation, "City", "${barber.city ?? ''}, ${barber.state ?? ''}"),
                        const Divider(color: Colors.white10, height: 16),
                        _buildDetailRow(
                          LucideIcons.globe,
                          "Coordinates",
                          "Lat: ${barber.latitude ?? 0.0}, Lng: ${barber.longitude ?? 0.0}",
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final url = Uri.parse("https://www.google.com/maps/search/?api=1&query=${barber.latitude},${barber.longitude}");
                              if (await canLaunchUrl(url)) {
                                await launchUrl(url, mode: LaunchMode.externalApplication);
                              }
                            },
                            icon: const Icon(LucideIcons.map, size: 16, color: AppColors.primary),
                            label: Text("Open in Google Maps", style: GoogleFonts.outfit(color: AppColors.primary, fontWeight: FontWeight.w600)),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: AppColors.primary.withOpacity(0.5)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // --- Services Catalog ---
                  _buildSectionCard(
                    title: "Services Catalog",
                    icon: LucideIcons.scissors,
                    child: (barber.services != null && barber.services!.isNotEmpty)
                        ? Column(
                            children: barber.services!.map((svc) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6.0),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF141420),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.white12),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(LucideIcons.scissors, size: 16, color: AppColors.primary),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              svc['name'] ?? 'N/A',
                                              style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                            ),
                                            Text(
                                              "${svc['duration_minutes'] ?? 30} mins duration",
                                              style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        "₹${svc['price'] ?? 0}",
                                        style: GoogleFonts.outfit(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          )
                        : Text("No services registered.", style: GoogleFonts.outfit(color: Colors.white54)),
                  ),
                  const SizedBox(height: 16),

                  // --- Documents (KYC) ---
                  _buildSectionCard(
                    title: "KYC Documents",
                    icon: LucideIcons.fileCheck,
                    child: (state.kycDocuments.isNotEmpty)
                        ? Column(
                            children: state.kycDocuments.map((doc) {
                              final docApproved = doc.status == 'approved';
                              final docRejected = doc.status == 'rejected';
                              final docColor = docApproved
                                  ? Colors.greenAccent
                                  : (docRejected ? Colors.redAccent : Colors.orangeAccent);

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF141420),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: Colors.white12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(LucideIcons.fileText, color: AppColors.primary, size: 20),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            doc.docType.replaceAll('_', ' ').toUpperCase(),
                                            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: docColor.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: docColor.withOpacity(0.4)),
                                          ),
                                          child: Text(
                                            doc.status.toUpperCase(),
                                            style: GoogleFonts.outfit(color: docColor, fontWeight: FontWeight.bold, fontSize: 10),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(LucideIcons.eye, color: Colors.white70, size: 20),
                                          onPressed: () => _showImageViewer(context, doc.docFrontUrl, doc.docType),
                                          tooltip: 'View Image',
                                        ),
                                      ],
                                    ),
                                    if (doc.status == 'pending' || doc.status == 'under_review') ...[
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: OutlinedButton(
                                              onPressed: () => _showKycRejectDialog(context, doc.id),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: Colors.redAccent,
                                                side: const BorderSide(color: Colors.redAccent),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                              ),
                                              child: const Text('REJECT'),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: ElevatedButton(
                                              onPressed: () {
                                                context.read<AdminBarberDetailsBloc>().add(ApproveKycDocumentEvent(doc.id));
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.green,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                              ),
                                              child: const Text('APPROVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                    if (doc.rejectReason != null && doc.rejectReason!.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                          'Reason: ${doc.rejectReason}',
                                          style: GoogleFonts.outfit(color: Colors.redAccent, fontSize: 12),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            }).toList(),
                          )
                        : Text("No KYC documents uploaded.", style: GoogleFonts.outfit(color: Colors.white54)),
                  ),
                  const SizedBox(height: 16),

                  // --- Barber Uploaded Documents ---
                  _buildSectionCard(
                    title: "Barber Documents",
                    icon: LucideIcons.fileCheck,
                    child: (state.barberDocuments.isNotEmpty)
                        ? Column(
                            children: state.barberDocuments.map((doc) {
                              final docApproved = doc.status == 'approved';
                              final docRejected = doc.status == 'rejected';
                              final docColor = docApproved
                                  ? Colors.greenAccent
                                  : (docRejected ? Colors.redAccent : Colors.orangeAccent);

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF141420),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: Colors.white12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(LucideIcons.fileText, color: AppColors.primary, size: 20),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            doc.docType.replaceAll('_', ' ').toUpperCase(),
                                            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: docColor.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: docColor.withOpacity(0.4)),
                                          ),
                                          child: Text(
                                            doc.status.toUpperCase(),
                                            style: GoogleFonts.outfit(color: docColor, fontWeight: FontWeight.bold, fontSize: 10),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(LucideIcons.eye, color: Colors.white70, size: 20),
                                          onPressed: () => _showImageViewer(context, doc.docUrl, doc.docType),
                                          tooltip: 'View Image',
                                        ),
                                      ],
                                    ),
                                    if (doc.status == 'pending') ...[
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: OutlinedButton(
                                              onPressed: () => _showBarberDocRejectDialog(context, doc.id),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: Colors.redAccent,
                                                side: const BorderSide(color: Colors.redAccent),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                              ),
                                              child: const Text('REJECT'),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: ElevatedButton(
                                              onPressed: () {
                                                context.read<AdminBarberDetailsBloc>().add(ApproveBarberDocumentEvent(doc.id));
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.green,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                              ),
                                              child: const Text('APPROVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                    if (doc.remarks != null && doc.remarks!.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                          'Remarks: ${doc.remarks}',
                                          style: GoogleFonts.outfit(color: Colors.redAccent, fontSize: 12),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            }).toList(),
                          )
                        : Text("No barber documents uploaded.", style: GoogleFonts.outfit(color: Colors.white54)),
                  ),
                  const SizedBox(height: 24),

                  // --- Action Buttons ---
                  if (StatusHelper.isPending(barber.verificationStatus))
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _showRejectDialog(context, barber.id),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                              side: const BorderSide(color: Colors.redAccent, width: 1.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: Text(
                              "REJECT",
                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _showApproveDialog(context, barber.id),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              elevation: 4,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: Text(
                              "APPROVE SHOP",
                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),

                  if (StatusHelper.isApproved(barber.verificationStatus) && StatusHelper.isActive(barber.status))
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _showSuspendDialog(context, barber.id),
                        icon: const Icon(LucideIcons.ban, color: Colors.black, size: 20),
                        label: Text(
                          "SUSPEND BARBER",
                          style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.black),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orangeAccent,
                          elevation: 4,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),

                  const SizedBox(height: 40),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
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
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.white54),
        const SizedBox(width: 10),
        Column(
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
      ],
    );
  }
}
