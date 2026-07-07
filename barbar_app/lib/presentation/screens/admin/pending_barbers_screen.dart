import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:barbar_app/presentation/bloc/admin/admin_barbers_bloc.dart';
import 'package:barbar_app/presentation/screens/admin/admin_barber_details_screen.dart';
import 'package:intl/intl.dart';

class PendingBarbersScreen extends StatefulWidget {
  const PendingBarbersScreen({Key? key}) : super(key: key);

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
      // Refresh list when coming back
      context.read<AdminBarbersBloc>().add(LoadPendingBarbers());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Barbers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<AdminBarbersBloc>().add(LoadPendingBarbers());
            },
          )
        ],
      ),
      body: BlocConsumer<AdminBarbersBloc, AdminBarbersState>(
        listener: (context, state) {
          if (state is AdminBarberActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message, style: const TextStyle(color: Colors.white)), backgroundColor: Colors.green),
            );
          } else if (state is AdminBarbersError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          if (state is AdminBarbersLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is AdminBarbersLoaded) {
            final barbers = state.barbers;
            if (barbers.isEmpty) {
              return const Center(child: Text("No pending barbers"));
            }
            return RefreshIndicator(
              onRefresh: () async {
                context.read<AdminBarbersBloc>().add(LoadPendingBarbers());
              },
              child: ListView.builder(
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

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundImage: barber.shopImage != null ? NetworkImage(barber.shopImage!) : null,
                                child: barber.shopImage == null ? const Icon(Icons.store) : null,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(barber.shopName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                    Text(barber.ownerName ?? 'Owner: N/A', style: const TextStyle(color: Colors.grey)),
                                    Text(barber.city, style: const TextStyle(color: Colors.grey)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Submitted:", style: TextStyle(fontSize: 12, color: Colors.grey)),
                                  Text(submittedDate, style: const TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Status:", style: TextStyle(fontSize: 12, color: Colors.grey)),
                                  Text(
                                    (barber.verificationStatus ?? 'Pending').toUpperCase(),
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Align(
                            alignment: Alignment.centerRight,
                            child: OutlinedButton(
                              onPressed: () => _navigateToDetails(context, barber.id),
                              child: const Text("View Details →"),
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

          return const Center(child: Text("Initialize state"));
        },
      ),
    );
  }
}
