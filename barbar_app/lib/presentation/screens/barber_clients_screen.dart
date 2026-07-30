import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../bloc/booking/booking_bloc.dart';
import '../bloc/booking/booking_event.dart';
import '../bloc/booking/booking_state.dart';
import '../../../data/models/booking_model.dart';

class BarberClientsScreen extends StatefulWidget {
  const BarberClientsScreen({super.key});

  @override
  State<BarberClientsScreen> createState() => _BarberClientsScreenState();
}

class _BarberClientsScreenState extends State<BarberClientsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    context.read<BookingBloc>().add(FetchBarberBookings());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F15),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F15),
        elevation: 0,
        centerTitle: true,
        title: Text(
          'CLIENT REPOSITORY',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.white,
            letterSpacing: 1.0,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, color: AppColors.primary, size: 20),
            onPressed: () {
              context.read<BookingBloc>().add(FetchBarberBookings());
            },
            tooltip: 'Refresh Clients',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: BlocConsumer<BookingBloc, BookingState>(
          listener: (context, state) {
            if (state is BookingFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.error),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is BookingLoading) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primary));
            }
            if (state is BookingsLoaded) {
              final Map<String, List<BookingModel>> clientBookings = {};
              for (var booking in state.bookings) {
                final name = booking.customerName.isNotEmpty ? booking.customerName : 'Guest Customer';
                if (!clientBookings.containsKey(name)) {
                  clientBookings[name] = [];
                }
                clientBookings[name]!.add(booking);
              }

              var clients = clientBookings.keys.toList();
              clients.sort((a, b) => a.compareTo(b));

              if (_searchQuery.isNotEmpty) {
                clients = clients.where((clientName) {
                  final list = clientBookings[clientName]!;
                  final phone = (list.first.customer?['phone'] as String?) ?? list.first.maskedCustomerPhone ?? '';
                  return clientName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                      phone.contains(_searchQuery);
                }).toList();
              }

              if (clients.isEmpty && _searchQuery.isEmpty) {
                return _buildEmptyState(context);
              }

              return Column(
                children: [
                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val.trim();
                        });
                      },
                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search client by name or phone...',
                        hintStyle: GoogleFonts.outfit(color: Colors.white38, fontSize: 14),
                        prefixIcon: const Icon(LucideIcons.search, size: 18, color: AppColors.primary),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(LucideIcons.x, size: 16, color: Colors.white54),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: const Color(0xFF1E1E2E),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Colors.white12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
                        ),
                      ),
                    ),
                  ),

                  Expanded(
                    child: RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: () async {
                        context.read<BookingBloc>().add(FetchBarberBookings());
                      },
                      child: clients.isEmpty
                          ? Center(
                              child: Text(
                                'No matching clients found',
                                style: GoogleFonts.outfit(color: Colors.white54, fontSize: 14),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                              itemCount: clients.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final clientName = clients[index];
                                final bookings = clientBookings[clientName]!;
                                bookings.sort((a, b) => b.scheduledStart.compareTo(a.scheduledStart));
                                return _buildClientCard(context, clientName, bookings);
                              },
                            ),
                    ),
                  ),
                ],
              );
            }
            return Center(
              child: Text(
                'No clients available',
                style: GoogleFonts.outfit(color: Colors.white54),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 1.5),
              ),
              child: const Icon(LucideIcons.users, size: 38, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            Text(
              'No Registered Clients Yet',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Clients who complete appointments at your salon will automatically appear here with full visit history.',
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: Colors.white54,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E1E2E),
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5), width: 1.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
              onPressed: () {
                context.read<BookingBloc>().add(FetchBarberBookings());
              },
              icon: const Icon(LucideIcons.refreshCw, size: 16, color: AppColors.primary),
              label: Text('Refresh Client List', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientCard(BuildContext context, String clientName, List<BookingModel> bookings) {
    final firstBooking = bookings.first;
    final phone = (firstBooking.customer?['phone'] as String?) ?? firstBooking.maskedCustomerPhone ?? '';
    
    // Calculate total spent
    double totalSpent = 0;
    for (var b in bookings) {
      totalSpent += b.finalPrice;
    }

    // Collect all unique services taken by this client
    final Set<String> uniqueServices = {};
    for (var b in bookings) {
      for (var s in b.services) {
        uniqueServices.add(s.name);
      }
    }

    final lastVisitIso = firstBooking.scheduledStart;
    final lastVisitFormatted = _formatDateShort(lastVisitIso);

    return InkWell(
      onTap: () => _showClientDetailsSheet(context, clientName, phone, totalSpent, bookings),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                  child: Text(
                    clientName.isNotEmpty ? clientName[0].toUpperCase() : 'C',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        clientName,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      if (phone.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(LucideIcons.phone, size: 12, color: Colors.white54),
                            const SizedBox(width: 4),
                            Text(
                              phone,
                              style: GoogleFonts.outfit(fontSize: 12, color: Colors.white54),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Last Visit',
                      style: GoogleFonts.outfit(fontSize: 11, color: Colors.white38),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      lastVisitFormatted,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(color: Colors.white10, height: 1),
            const SizedBox(height: 12),

            // Metrics Badges Row
            Row(
              children: [
                _badgeChip('${bookings.length} Total Visits', AppColors.primary),
                const SizedBox(width: 8),
                _badgeChip('₹${totalSpent.toStringAsFixed(0)} Spent', AppColors.success),
              ],
            ),

            // Services Taken Chips
            if (uniqueServices.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: uniqueServices.take(4).map((s) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Text(
                      s,
                      style: GoogleFonts.outfit(fontSize: 11, color: Colors.white70),
                    ),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Tap to view complete visit history',
                  style: GoogleFonts.outfit(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 4),
                const Icon(LucideIcons.chevronRight, size: 14, color: AppColors.primary),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _badgeChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  void _showClientDetailsSheet(
    BuildContext context,
    String clientName,
    String phone,
    double totalSpent,
    List<BookingModel> bookings,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Color(0xFF141420),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: AppColors.primary, width: 1.5)),
        ),
        child: Column(
          children: [
            // Handle bar
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Header Client Summary Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                    child: Text(
                      clientName.isNotEmpty ? clientName[0].toUpperCase() : 'C',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        fontSize: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          clientName,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                        if (phone.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            phone,
                            style: GoogleFonts.outfit(fontSize: 13, color: Colors.white54),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x, color: Colors.white54),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Summary Stats Strip
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E2E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _statItem('Total Visits', '${bookings.length}', AppColors.primary),
                    Container(height: 30, width: 1, color: Colors.white10),
                    _statItem('Total Revenue', '₹${totalSpent.toStringAsFixed(0)}', AppColors.success),
                    Container(height: 30, width: 1, color: Colors.white10),
                    _statItem('Avg Per Visit', '₹${(totalSpent / (bookings.isEmpty ? 1 : bookings.length)).toStringAsFixed(0)}', AppColors.info),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Icon(LucideIcons.history, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'VISIT HISTORY & SERVICES',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppColors.primary,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                itemCount: bookings.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final booking = bookings[index];
                  return _buildVisitHistoryCard(booking);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.outfit(fontSize: 11, color: Colors.white54),
        ),
      ],
    );
  }

  Widget _buildVisitHistoryCard(BookingModel booking) {
    final dt = DateTime.tryParse(booking.scheduledStart);
    final dateStr = dt != null ? DateFormat('MMM dd, yyyy • hh:mm a').format(dt) : booking.scheduledStart;

    Color statusColor = AppColors.info;
    if (booking.status == 'completed') statusColor = AppColors.success;
    else if (booking.status == 'cancelled' || booking.status == 'no_show') statusColor = AppColors.error;
    else if (booking.status == 'in_progress') statusColor = AppColors.warning;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    booking.isHomeService ? LucideIcons.home : LucideIcons.scissors,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    booking.isHomeService ? 'Home Service' : 'Shop Visit',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  booking.status.toUpperCase(),
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 10, color: statusColor),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(LucideIcons.calendar, size: 13, color: Colors.white38),
              const SizedBox(width: 6),
              Text(dateStr, style: GoogleFonts.outfit(fontSize: 12, color: Colors.white54)),
            ],
          ),

          const SizedBox(height: 10),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 10),

          Text(
            'Services Taken:',
            style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70),
          ),
          const SizedBox(height: 6),

          if (booking.services.isEmpty)
            Text('General Grooming Service', style: GoogleFonts.outfit(fontSize: 12, color: Colors.white54))
          else
            Column(
              children: booking.services.map((s) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(LucideIcons.check, size: 12, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text(s.name, style: GoogleFonts.outfit(fontSize: 13, color: Colors.white)),
                        ],
                      ),
                      Text('₹${s.price.toStringAsFixed(0)}', style: GoogleFonts.outfit(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w500)),
                    ],
                  ),
                );
              }).toList(),
            ),

          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount:',
                style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              Text(
                '₹${booking.finalPrice.toStringAsFixed(0)}',
                style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDateShort(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return DateFormat('yyyy-MM-dd').format(dt);
    } catch (_) {
      return iso.split('T').first;
    }
  }
}
