import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:barbar_app/core/theme/app_theme.dart';
import 'package:barbar_app/presentation/bloc/admin/admin_barbers_bloc.dart';
import 'package:barbar_app/presentation/screens/admin/admin_barber_details_screen.dart';
import 'package:intl/intl.dart';

class PendingBarbersScreen extends StatefulWidget {
  final bool showAppBar;
  const PendingBarbersScreen({Key? key, this.showAppBar = true}) : super(key: key);

  @override
  State<PendingBarbersScreen> createState() => _PendingBarbersScreenState();
}

class _PendingBarbersScreenState extends State<PendingBarbersScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AdminBarbersBloc>().add(LoadPendingBarbers());
  }

  void _navigateToDetails(BuildContext context, String barberId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => AdminBarberDetailsScreen(barberId: barberId),
      ),
    ).then((_) {
      context.read<AdminBarbersBloc>().add(LoadPendingBarbers());
    });
  }

  @override
  Widget build(BuildContext context) {
    final bodyContent = Container(
      color: AppColors.background,
      child: BlocConsumer<AdminBarbersBloc, AdminBarbersState>(
        listener: (context, state) {
          if (state is AdminBarberActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message, style: GoogleFonts.outfit(color: Colors.white)), backgroundColor: AppColors.success),
            );
          } else if (state is AdminBarbersError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message, style: GoogleFonts.outfit(color: Colors.white)), backgroundColor: AppColors.error),
            );
          }
        },
        builder: (context, state) {
          if (state is AdminBarbersLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          if (state is AdminBarbersLoaded) {
            final barbers = state.barbers;
            if (barbers.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.checkCircle2, size: 48, color: AppColors.textMuted),
                    const SizedBox(height: 12),
                    Text("No pending barber approvals", style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 16)),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                context.read<AdminBarbersBloc>().add(LoadPendingBarbers());
              },
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemCount: barbers.length,
                itemBuilder: (context, index) {
                  final barber = barbers[index];
                  String submittedDate = "N/A";
                  if (barber.createdAt != null) {
                    final dt = DateTime.tryParse(barber.createdAt!);
                    if (dt != null) {
                      submittedDate = DateFormat('dd MMM yyyy').format(dt);
                    }
                  }

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border, width: 1),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                               ClipRRect(
                                 borderRadius: BorderRadius.circular(24),
                                 child: (barber.fullShopImage != null && barber.fullShopImage!.isNotEmpty)
                                     ? CachedNetworkImage(
                                         imageUrl: barber.fullShopImage!,
                                         width: 48,
                                         height: 48,
                                         fit: BoxFit.cover,
                                         placeholder: (_, __) => Container(
                                           width: 48,
                                           height: 48,
                                           color: AppColors.surface,
                                           child: const Center(
                                             child: SizedBox(
                                               width: 16,
                                               height: 16,
                                               child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                                             ),
                                           ),
                                         ),
                                         errorWidget: (_, __, ___) => Container(
                                           width: 48,
                                           height: 48,
                                           color: AppColors.surface,
                                           child: const Icon(LucideIcons.scissors, color: AppColors.primary, size: 20),
                                         ),
                                       )
                                     : Container(
                                         width: 48,
                                         height: 48,
                                         decoration: const BoxDecoration(
                                           color: AppColors.surface,
                                           shape: BoxShape.circle,
                                         ),
                                         child: const Icon(LucideIcons.scissors, color: AppColors.primary, size: 20),
                                       ),
                               ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      barber.shopName,
                                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 17, color: AppColors.textPrimary),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(LucideIcons.user, color: AppColors.textSecondary, size: 13),
                                        Text(
                                          " ${barber.ownerName ?? 'Owner: N/A'}",
                                          style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 13),
                                        ),
                                        const SizedBox(width: 10),
                                        const Icon(LucideIcons.mapPin, color: AppColors.textSecondary, size: 13),
                                        Text(
                                          " ${barber.city}",
                                          style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.warning.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppColors.warning.withOpacity(0.3), width: 1),
                                ),
                                child: Text(
                                  (barber.verificationStatus ?? 'Pending').toUpperCase(),
                                  style: GoogleFonts.outfit(
                                    color: AppColors.warning,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              )
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border, width: 1),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(LucideIcons.calendar, size: 14, color: AppColors.textSecondary),
                                    const SizedBox(width: 6),
                                    Text("Submitted: ", style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondary)),
                                    Text(submittedDate, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                  ],
                                ),
                                Text(
                                  "Requires Verification",
                                  style: GoogleFonts.outfit(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => _navigateToDetails(context, barber.id),
                              icon: const Icon(LucideIcons.arrowRight, size: 16, color: AppColors.primary),
                              label: Text(
                                "Review & Approve Details",
                                style: GoogleFonts.outfit(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.primary, width: 1),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          }

          if (state is AdminBarbersError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.alertTriangle, color: AppColors.error, size: 48),
                  const SizedBox(height: 12),
                  Text("Error: ${state.message}", style: GoogleFonts.outfit(color: AppColors.textSecondary)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => context.read<AdminBarbersBloc>().add(LoadPendingBarbers()),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.black),
                    child: Text("Retry", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                  )
                ],
              ),
            );
          }

          return Center(child: Text("Initialize state", style: GoogleFonts.outfit(color: AppColors.textMuted)));
        },
      ),
    );

    if (!widget.showAppBar) {
      return bodyContent;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Pending Barbers', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            onPressed: () {
              context.read<AdminBarbersBloc>().add(LoadPendingBarbers());
            },
          )
        ],
      ),
      body: bodyContent,
    );
  }
}
