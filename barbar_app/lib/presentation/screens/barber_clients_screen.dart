import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
        title: const Text('CLIENTS'),
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
            clients.sort((a, b) => a.compareTo(b)); // Simple alphabetical sort

            if (clients.isEmpty) {
              return const Center(child: Text('No clients found', style: TextStyle(color: AppColors.textSecondary)));
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

                return GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.surface,
                        child: const Icon(LucideIcons.user, color: AppColors.textSecondary, size: 20),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(clientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 4),
                            Text(
                              'Total Visits: ${bookings.length}',
                              style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Last Visit', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                          const SizedBox(height: 2),
                          Text(
                            lastVisit,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          }
          return const Center(child: Text('No clients available'));
        },
      ),
    );
  }
}
