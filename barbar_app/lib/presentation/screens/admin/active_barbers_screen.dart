import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:barbar_app/presentation/bloc/admin/admin_barbers_bloc.dart';
import 'package:barbar_app/presentation/screens/admin/admin_barber_details_screen.dart';

class ActiveBarbersScreen extends StatefulWidget {
  const ActiveBarbersScreen({Key? key}) : super(key: key);

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
        title: const Text('Suspend Barber?'),
        content: const Text('Are you sure you want to suspend this barber? They will be hidden from the customer map.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AdminBarbersBloc>().add(SuspendBarberEvent(barberId));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Suspend'),
          ),
        ],
      ),
    );
  }
  
  void _showActivateDialog(BuildContext context, String barberId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Activate Barber?'),
        content: const Text('This barber will become visible to customers again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AdminBarbersBloc>().add(ActivateBarberEvent(barberId));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Activate'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Barbers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<AdminBarbersBloc>().add(LoadActiveBarbers());
            },
          )
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search barbers...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter),
                    selected: _filter == filter,
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
                  final barbers = state.barbers.where((b) {
                    // Filter by Search Query
                    if (_searchQuery.isNotEmpty && !b.shopName.toLowerCase().contains(_searchQuery)) {
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
                    return const Center(child: Text("No barbers found"));
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      context.read<AdminBarbersBloc>().add(LoadActiveBarbers());
                    },
                    child: ListView.builder(
                      itemCount: barbers.length,
                      itemBuilder: (context, index) {
                        final barber = barbers[index];
                        final isSuspended = barber.status == 'suspended';
                        final isOnline = barber.status == 'active' && barber.isAvailable;

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
                                          Row(
                                            children: [
                                              Icon(Icons.circle, size: 12, color: isOnline ? Colors.green : Colors.grey),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  barber.shopName,
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              const Icon(Icons.star, color: Colors.amber, size: 16),
                                              Text(" ${barber.rating.toStringAsFixed(1)}"),
                                            ],
                                          ),
                                          Text(barber.ownerName ?? 'Owner: N/A', style: const TextStyle(color: Colors.grey)),
                                          Text(barber.city, style: const TextStyle(color: Colors.grey)),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isSuspended ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        (barber.status ?? 'active').toUpperCase(),
                                        style: TextStyle(
                                          color: isSuspended ? Colors.red : Colors.green,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text("Today's Bookings", style: TextStyle(fontSize: 12, color: Colors.grey)),
                                        Text("0", style: const TextStyle(fontWeight: FontWeight.bold)), // TODO: Parse from backend if available
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text("Current Queue", style: TextStyle(fontSize: 12, color: Colors.grey)),
                                        Text("${barber.currentQueueLength}", style: const TextStyle(fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    OutlinedButton(
                                      onPressed: () => _navigateToDetails(context, barber.id),
                                      child: const Text("View Details"),
                                    ),
                                    if (isSuspended)
                                      ElevatedButton(
                                        onPressed: () => _showActivateDialog(context, barber.id),
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                        child: const Text("Activate"),
                                      )
                                    else
                                      ElevatedButton(
                                        onPressed: () => _showSuspendDialog(context, barber.id),
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                                        child: const Text("Suspend"),
                                      )
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

                return const Center(child: Text("Initialize state"));
              },
            ),
          ),
        ],
      ),
    );
  }
}
