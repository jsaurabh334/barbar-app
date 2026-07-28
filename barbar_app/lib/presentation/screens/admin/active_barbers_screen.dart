import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:barbar_app/core/theme/app_theme.dart';
import 'package:barbar_app/presentation/bloc/admin/admin_barbers_bloc.dart';
import 'package:barbar_app/presentation/screens/admin/admin_barber_details_screen.dart';

class ActiveBarbersScreen extends StatefulWidget {
  final bool showAppBar;
  const ActiveBarbersScreen({Key? key, this.showAppBar = true}) : super(key: key);

  @override
  State<ActiveBarbersScreen> createState() => _ActiveBarbersScreenState();
}

class _ActiveBarbersScreenState extends State<ActiveBarbersScreen> {
  String _searchQuery = '';
  String _filter = 'All'; // All, Active, Suspended, Online, Offline

  @override
  void initState() {
    super.initState();
    context.read<AdminBarbersBloc>().add(LoadActiveBarbers());
  }

  void _navigateToDetails(BuildContext context, String barberId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => AdminBarberDetailsScreen(barberId: barberId),
      ),
    ).then((_) {
      context.read<AdminBarbersBloc>().add(LoadActiveBarbers());
    });
  }

  void _showSuspendDialog(BuildContext context, String barberId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: Text('Suspend Barber?', style: GoogleFonts.outfit(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to suspend this barber? They will be hidden from the customer map.', style: GoogleFonts.outfit(color: AppColors.textSecondary)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.border)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.outfit(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AdminBarbersBloc>().add(SuspendBarberEvent(barberId));
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning, foregroundColor: Colors.black),
            child: Text('Suspend', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
  
  void _showActivateDialog(BuildContext context, String barberId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: Text('Activate Barber?', style: GoogleFonts.outfit(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        content: Text('This barber will become visible to customers again.', style: GoogleFonts.outfit(color: AppColors.textSecondary)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.border)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.outfit(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AdminBarbersBloc>().add(ActivateBarberEvent(barberId));
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white),
            child: Text('Activate', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bodyContent = Container(
      color: AppColors.background,
      child: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: TextField(
              style: GoogleFonts.outfit(color: AppColors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search by barber shop, city, or owner...',
                hintStyle: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 14),
                prefixIcon: const Icon(LucideIcons.search, color: AppColors.textSecondary, size: 18),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border, width: 1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.toLowerCase();
                });
              },
            ),
          ),
          
          // Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: ['All', 'Active', 'Suspended', 'Online', 'Offline'].map((filter) {
                final isSelected = _filter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter),
                    labelStyle: GoogleFonts.outfit(
                      color: isSelected ? Colors.black : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 13,
                    ),
                    selected: isSelected,
                    backgroundColor: AppColors.surface,
                    selectedColor: AppColors.primary,
                    checkmarkColor: Colors.black,
                    showCheckmark: isSelected,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? AppColors.primary : AppColors.border,
                        width: 1,
                      ),
                    ),
                    onSelected: (selected) {
                      setState(() {
                        _filter = filter;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          
          // List
          Expanded(
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
                  final barbers = state.barbers.where((b) {
                    // Filter by Search Query
                    if (_searchQuery.isNotEmpty && !b.shopName.toLowerCase().contains(_searchQuery) && !(b.ownerName?.toLowerCase().contains(_searchQuery) ?? false) && !b.city.toLowerCase().contains(_searchQuery)) {
                      return false;
                    }
                    // Filter by Chips
                    if (_filter == 'Active' && b.status != 'active') return false;
                    if (_filter == 'Suspended' && b.status != 'suspended') return false;
                    if (_filter == 'Online' && (b.status != 'active' || !b.isAvailable)) return false;
                    if (_filter == 'Offline' && (b.status == 'active' && b.isAvailable)) return false;
                    
                    return true;
                  }).toList();

                  if (barbers.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.scissors, size: 48, color: AppColors.textMuted),
                          const SizedBox(height: 12),
                          Text("No barbers found", style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 16)),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () async {
                      context.read<AdminBarbersBloc>().add(LoadActiveBarbers());
                    },
                    child: ListView.builder(
                      itemCount: barbers.length,
                      padding: const EdgeInsets.only(bottom: 24),
                      itemBuilder: (context, index) {
                        final barber = barbers[index];
                        final isSuspended = barber.status == 'suspended';
                        final isOnline = barber.status == 'active' && barber.isAvailable;

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
                                          Row(
                                            children: [
                                              Container(
                                                width: 8,
                                                height: 8,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: isOnline ? AppColors.success : AppColors.textMuted,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  barber.shopName,
                                                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 17, color: AppColors.textPrimary),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(LucideIcons.star, color: Colors.amber, size: 14),
                                              Text(
                                                " ${barber.rating.toStringAsFixed(1)}",
                                                style: GoogleFonts.outfit(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                                              ),
                                              const SizedBox(width: 10),
                                              const Icon(LucideIcons.mapPin, color: AppColors.textSecondary, size: 13),
                                              Text(
                                                " ${barber.city}",
                                                style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 13),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            "Owner: ${barber.ownerName ?? 'N/A'}",
                                            style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isSuspended ? AppColors.error.withOpacity(0.15) : AppColors.success.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: isSuspended ? AppColors.error.withOpacity(0.3) : AppColors.success.withOpacity(0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        (barber.status ?? 'active').toUpperCase(),
                                        style: GoogleFonts.outfit(
                                          color: isSuspended ? AppColors.error : AppColors.success,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                                const SizedBox(height: 16),
                                // Stats container
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.border, width: 1),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: [
                                      Column(
                                        children: [
                                          Text("Today's Bookings", style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondary)),
                                          const SizedBox(height: 2),
                                          Text("0", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                                        ],
                                      ),
                                      Container(width: 1, height: 28, color: AppColors.border),
                                      Column(
                                        children: [
                                          Text("Current Queue", style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondary)),
                                          const SizedBox(height: 2),
                                          Text("${barber.currentQueueLength}", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () => _navigateToDetails(context, barber.id),
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(color: AppColors.border, width: 1),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                        ),
                                        child: Text(
                                          "View Details",
                                          style: GoogleFonts.outfit(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: isSuspended
                                          ? ElevatedButton(
                                              onPressed: () => _showActivateDialog(context, barber.id),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: AppColors.success,
                                                foregroundColor: Colors.white,
                                                elevation: 0,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                padding: const EdgeInsets.symmetric(vertical: 12),
                                              ),
                                              child: Text(
                                                "Activate",
                                                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
                                              ),
                                            )
                                          : ElevatedButton(
                                              onPressed: () => _showSuspendDialog(context, barber.id),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: AppColors.warning,
                                                foregroundColor: Colors.black,
                                                elevation: 0,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                padding: const EdgeInsets.symmetric(vertical: 12),
                                              ),
                                              child: Text(
                                                "Suspend",
                                                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
                                              ),
                                            ),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }

                return Center(child: Text("Initialize state", style: GoogleFonts.outfit(color: AppColors.textMuted)));
              },
            ),
          ),
        ],
      ),
    );

    if (!widget.showAppBar) {
      return bodyContent;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Active Barbers', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            onPressed: () {
              context.read<AdminBarbersBloc>().add(LoadActiveBarbers());
            },
          )
        ],
      ),
      body: bodyContent,
    );
  }
}
