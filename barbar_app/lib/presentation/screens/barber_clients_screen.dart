import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_theme.dart';
import '../bloc/booking/booking_bloc.dart';
import '../bloc/booking/booking_state.dart';
import '../../../data/models/booking_model.dart';
import '../widgets/glass_card.dart';

class BarberClientsScreen extends StatelessWidget {
  const BarberClientsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'CLIENT REPOSITORY',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: AppColors.textPrimary,
            letterSpacing: 1.0,
          ),
        ),
      ),
      body: BlocBuilder<BookingBloc, BookingState>(
        builder: (context, state) {
          if (state is BookingLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (state is BookingsLoaded) {
            final Map<String, List<BookingModel>> clientBookings = {};
            for (var booking in state.bookings) {
              if (!clientBookings.containsKey(booking.customerName)) {
                clientBookings[booking.customerName] = [];
              }
              clientBookings[booking.customerName]!.add(booking);
            }

            final clients = clientBookings.keys.toList();
            clients.sort((a, b) => a.compareTo(b));

            if (clients.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.5),
                        ),
                        child: const Icon(LucideIcons.users, size: 36, color: AppColors.primary),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'No Registered Clients Yet',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Clients who complete appointments at your salon will automatically appear here with visit history.',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: clients.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final clientName = clients[index];
                final bookings = clientBookings[clientName]!;
                bookings.sort((a, b) => b.scheduledStart.compareTo(a.scheduledStart));
                final lastVisit = bookings.first.scheduledStart.split('T').first;

                return Container(
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                          child: Text(
                            clientName.isNotEmpty ? clientName[0].toUpperCase() : 'C',
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 16),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                clientName,
                                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${bookings.length} Total Visits',
                                  style: GoogleFonts.outfit(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Last Visit', style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textMuted)),
                            const SizedBox(height: 2),
                            Text(
                              lastVisit,
                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
          return Center(child: Text('No clients available', style: GoogleFonts.outfit(color: AppColors.textSecondary)));
        },
      ),
    );
  }
}
