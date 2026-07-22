import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:barbar_app/presentation/bloc/admin/admin_barber_details_bloc.dart';
import 'package:barbar_app/domain/repositories/admin_repository.dart';
import 'package:intl/intl.dart';
import 'package:barbar_app/core/utils/status_helper.dart';

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
        title: const Text('Reject Application'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'Reason',
            hintText: 'e.g. Shop license is blurred',
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              context.read<AdminBarberDetailsBloc>().add(
                    RejectBarberDetailsEvent(barberId, reasonController.text.trim()),
                  );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
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
        title: const Text('Reject Document'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'Rejection Reason',
            hintText: 'e.g. Image is blurry, name mismatch',
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              context.read<AdminBarberDetailsBloc>().add(
                    RejectKycDocumentEvent(documentId, reasonController.text.trim()),
                  );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _showImageViewer(BuildContext context, String url, String title) {
    // Advanced image viewer: zoom, rotate, download
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
                        child: Image.network(
                          url,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(Icons.broken_image, color: Colors.white, size: 50),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 40,
                    right: 20,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 30),
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
                          icon: const Icon(Icons.rotate_left, color: Colors.white, size: 30),
                          onPressed: () {
                            setState(() => _rotation -= 1.5708); // -90 deg
                          },
                        ),
                        const SizedBox(width: 20),
                        IconButton(
                          icon: const Icon(Icons.rotate_right, color: Colors.white, size: 30),
                          onPressed: () {
                            setState(() => _rotation += 1.5708); // +90 deg
                          },
                        ),
                        const SizedBox(width: 20),
                        IconButton(
                          icon: const Icon(Icons.download, color: Colors.white, size: 30),
                          onPressed: () {
                            // Mock download
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Downloading image...')));
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
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
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
        title: const Text('Approve this barber?'),
        content: const Text('Are you sure you want to approve this application? They will become active immediately.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AdminBarberDetailsBloc>().add(ApproveBarberDetailsEvent(barberId));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }
  
  void _showSuspendDialog(BuildContext context, String barberId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Suspend Barber?'),
        content: const Text('Are you sure you want to suspend this barber? They will be hidden from the map.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AdminBarberDetailsBloc>().add(SuspendBarberDetailsEvent(barberId));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Suspend'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Barber Details'),
      ),
      body: BlocConsumer<AdminBarberDetailsBloc, AdminBarberDetailsState>(
        listener: (context, state) {
          if (state is AdminBarberDetailsActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message, style: const TextStyle(color: Colors.white)), backgroundColor: Colors.green),
            );
          } else if (state is AdminBarberDetailsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          if (state is AdminBarberDetailsLoading || state is AdminBarberDetailsInitial) {
            return const Center(child: CircularProgressIndicator());
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

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Header ---
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundImage: barber.shopImage != null ? NetworkImage(barber.shopImage!) : null,
                        child: barber.shopImage == null ? const Icon(Icons.store, size: 40) : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(barber.shopName, style: Theme.of(context).textTheme.headlineSmall),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: StatusHelper.isApproved(barber.verificationStatus) ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                (barber.verificationStatus ?? 'pending').toUpperCase(),
                                style: TextStyle(
                                  color: StatusHelper.isApproved(barber.verificationStatus) ? Colors.green : Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text("Submitted: $submittedDate", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      )
                    ],
                  ),
                  const Divider(height: 32),

                  // --- Owner Information ---
                  const Text("Owner Information", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.person),
                    title: Text(barber.ownerName ?? 'N/A'),
                    subtitle: Text(barber.phone ?? 'N/A'),
                  ),
                  const Divider(height: 32),

                  // --- Shop Information ---
                  const Text("Shop Information", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.location_on),
                    title: Text("${barber.address}"),
                    subtitle: Text("${barber.city}"),
                  ),
                  const Divider(height: 32),
                  
                  // --- Location ---
                  const Text("Location", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text("Lat: ${barber.latitude}, Lng: ${barber.longitude}"),
                  TextButton.icon(
                    onPressed: () {
                      // Open maps logic
                    },
                    icon: const Icon(Icons.map),
                    label: const Text("Open in Maps"),
                  ),
                  const Divider(height: 32),

                  // --- Services ---
                  const Text("Services", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (barber.services != null && barber.services!.isNotEmpty)
                    DataTable(
                      columns: const [
                        DataColumn(label: Text('Service')),
                        DataColumn(label: Text('Duration')),
                        DataColumn(label: Text('Price')),
                      ],
                      rows: barber.services!.map((svc) {
                        return DataRow(cells: [
                          DataCell(Text(svc['name'] ?? 'N/A')),
                          DataCell(Text("${svc['duration_minutes'] ?? 0} min")),
                          DataCell(Text("₹${svc['price'] ?? 0}")),
                        ]);
                      }).toList(),
                    )
                  else
                    const Text("No services added."),
                  const Divider(height: 32),

                  // --- Documents (KYC) ---
                  const Text("Documents (KYC)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (state.kycDocuments.isNotEmpty)
                    ...state.kycDocuments.map((doc) => Card(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ListTile(
                                leading: const Icon(Icons.file_present),
                                title: Text(doc.docType),
                                subtitle: Text(
                                  doc.status.toUpperCase(),
                                  style: TextStyle(
                                    color: doc.status == 'approved' ? Colors.green : (doc.status == 'rejected' ? Colors.red : Colors.orange),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.zoom_in),
                                      onPressed: () => _showImageViewer(context, doc.docFrontUrl, doc.docType),
                                      tooltip: 'View Document',
                                    ),
                                  ],
                                ),
                              ),
                              if (doc.status == 'pending' || doc.status == 'under_review')
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () => _showKycRejectDialog(context, doc.id),
                                          style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                                          child: const Text('REJECT'),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () {
                                            context.read<AdminBarberDetailsBloc>().add(ApproveKycDocumentEvent(doc.id));
                                          },
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                          child: const Text('APPROVE'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (doc.rejectReason != null)
                                Padding(
                                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                                  child: Text('Reason: ${doc.rejectReason}', style: const TextStyle(color: Colors.red)),
                                ),
                            ],
                          ),
                        ))
                  else
                    const Text("No KYC documents found."),

                  const SizedBox(height: 32),

                  // --- Actions ---
                  if (StatusHelper.isPending(barber.verificationStatus))
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _showRejectDialog(context, barber.id),
                            style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                            child: const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text("REJECT"),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _showApproveDialog(context, barber.id),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                            child: const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text("APPROVE"),
                            ),
                          ),
                        ),
                      ],
                    ),
                  
                  if (StatusHelper.isApproved(barber.verificationStatus) && StatusHelper.isActive(barber.status))
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _showSuspendDialog(context, barber.id),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                        child: const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text("SUSPEND BARBER"),
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
}
