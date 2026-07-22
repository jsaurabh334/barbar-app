import 'package:barbar_app/presentation/bloc/admin/admin_bookings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AdminBookingDetailScreen extends StatefulWidget {
  final Map<String, dynamic> bookingData;

  const AdminBookingDetailScreen({super.key, required this.bookingData});

  @override
  State<AdminBookingDetailScreen> createState() => _AdminBookingDetailScreenState();
}

class _AdminBookingDetailScreenState extends State<AdminBookingDetailScreen> {
  late Map<String, dynamic> _booking;
  List<dynamic> _timeline = [];

  @override
  void initState() {
    super.initState();
    _booking = widget.bookingData;
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    try {
      final repo = context.read<AdminBookingsBloc>().adminRepository;
      final detail = await repo.getAdminBookingDetail(_booking['id'] as String);
      if (mounted) {
        setState(() => _booking = detail);
      }
    } catch (_) {}
    try {
      final repo = context.read<AdminBookingsBloc>().adminRepository;
      final timeline = await repo.getAdminBookingTimeline(_booking['id'] as String);
      if (mounted) {
        setState(() => _timeline = timeline);
      }
    } catch (_) {}
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'confirmed': return Colors.blue;
      case 'in_progress': return Colors.green;
      case 'completed': return Colors.teal;
      case 'cancelled': return Colors.red;
      case 'no_show': return Colors.grey;
      case 'rescheduled': return Colors.purple;
      default: return Colors.grey;
    }
  }

  String _fmt(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }

  Future<void> _showCancelDialog() async {
    final reasonController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            hintText: 'Enter cancellation reason',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Back')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, reasonController.text),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cancel Booking'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      if (!mounted) return;
      context.read<AdminBookingsBloc>().add(CancelBooking(_booking['id'] as String, result));
    }
  }

  Future<void> _showRescheduleDialog() async {
    final dateController = TextEditingController();
    final timeController = TextEditingController();
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reschedule Booking'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: dateController,
              decoration: const InputDecoration(labelText: 'New Date', hintText: 'YYYY-MM-DD'),
              readOnly: true,
              onTap: () async {
                final picked = await showDatePicker(
                  context: ctx,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 90)),
                );
                if (picked != null) dateController.text = picked.toIso8601String().split('T')[0];
              },
            ),
            const SizedBox(height: 8),
            TextField(
              controller: timeController,
              decoration: const InputDecoration(labelText: 'New Time', hintText: 'HH:MM (24h)'),
              onTap: () async {
                final picked = await showTimePicker(
                  context: ctx,
                  initialTime: TimeOfDay.now(),
                );
                if (picked != null) {
                  timeController.text = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Back')),
          ElevatedButton(
            onPressed: () {
              if (dateController.text.isNotEmpty && timeController.text.isNotEmpty) {
                Navigator.pop(ctx, {'date': dateController.text, 'time': timeController.text});
              }
            },
            child: const Text('Reschedule'),
          ),
        ],
      ),
    );

    if (result != null) {
      final newStart = '${result['date']}T${result['time']}:00';
      final dt = DateTime.parse(newStart);
      final newEnd = dt.add(const Duration(hours: 1)).toIso8601String();
      if (!mounted) return;
      context.read<AdminBookingsBloc>().add(RescheduleBooking(
        bookingId: _booking['id'] as String,
        newStart: newStart,
        newEnd: newEnd,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final id = _booking['id'] as String? ?? '';
    final status = _booking['status'] as String? ?? 'unknown';
    final customerName = _booking['customer']?['full_name'] as String? ?? _booking['customer_name'] as String? ?? 'Guest';
    final customerPhone = _booking['customer']?['phone'] as String? ?? '';
    final shopName = _booking['barber']?['shop_name'] as String? ?? _booking['shop_name'] as String? ?? '';
    final barberAddress = _booking['barber']?['address'] as String? ?? '';
    final scheduledStart = _booking['scheduled_start'] as String? ?? '';
    final scheduledEnd = _booking['scheduled_end'] as String? ?? '';
    final price = ( _booking['final_price'] as num?)?.toDouble() ?? 0.0;
    final totalPrice = ( _booking['total_price'] as num?)?.toDouble() ?? 0.0;
    final discount = ( _booking['discount_amount'] as num?)?.toDouble() ?? 0.0;
    final paymentStatus = _booking['payment_status'] as String? ?? '';
    final paymentMethod = _booking['payment_method'] as String? ?? '';
    final cancellationReason = _booking['cancellation_reason'] as String?;
    final isHomeService = _booking['is_home_service'] as bool? ?? false;
    final homeAddress = _booking['home_service_address'] as String? ?? '';
    final services = (_booking['services'] as List<dynamic>?) ?? [];

    return BlocListener<AdminBookingsBloc, AdminBookingsState>(
      listener: (context, state) {
        if (state is AdminBookingActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
          Navigator.pop(context, true);
        } else if (state is AdminBookingsError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.red));
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Booking Detail'),
          actions: [
            if (status != 'cancelled' && status != 'completed')
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'cancel') _showCancelDialog();
                  if (v == 'reschedule') _showRescheduleDialog();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'cancel', child: ListTile(leading: Icon(Icons.cancel, color: Colors.red), title: Text('Cancel'))),
                  const PopupMenuItem(value: 'reschedule', child: ListTile(leading: Icon(Icons.schedule), title: Text('Reschedule'))),
                ],
              ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _loadDetail,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusHeader(status, id),
                const SizedBox(height: 16),
                _buildSection('Customer', [
                  _infoRow(Icons.person, customerName),
                  if (customerPhone.isNotEmpty) _infoRow(Icons.phone, customerPhone),
                ]),
                const SizedBox(height: 12),
                _buildSection('Shop', [
                  _infoRow(Icons.store, shopName),
                  if (barberAddress.isNotEmpty) _infoRow(Icons.location_on, barberAddress),
                ]),
                const SizedBox(height: 12),
                _buildSection('Schedule', [
                  _infoRow(Icons.play_arrow, _fmt(scheduledStart)),
                  _infoRow(Icons.stop, _fmt(scheduledEnd)),
                  if (isHomeService) _infoRow(Icons.home, homeAddress),
                ]),
                const SizedBox(height: 12),
                if (services.isNotEmpty)
                  _buildSection('Services', services.map<Widget>((s) {
                    final name = s['service_name'] as String? ?? '';
                    final svcPrice = (s['total_price'] as num?)?.toDouble() ?? 0.0;
                    return ListTile(dense: true, leading: const Icon(Icons.content_cut, size: 18), title: Text(name), trailing: Text('₹${svcPrice.toStringAsFixed(0)}'));
                  }).toList()),
                const SizedBox(height: 12),
                _buildSection('Payment', [
                  _infoRow(Icons.currency_rupee, 'Total: ₹${totalPrice.toStringAsFixed(2)}'),
                  if (discount > 0) _infoRow(Icons.discount, 'Discount: -₹${discount.toStringAsFixed(2)}'),
                  _infoRow(Icons.payments, 'Final: ₹${price.toStringAsFixed(2)}'),
                  _infoRow(Icons.check_circle_outline, 'Status: $paymentStatus'),
                  if (paymentMethod.isNotEmpty) _infoRow(Icons.credit_card, 'Method: $paymentMethod'),
                ]),
                if (cancellationReason != null && cancellationReason.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildSection('Cancellation', [
                    _infoRow(Icons.info_outline, cancellationReason, color: Colors.red),
                  ]),
                ],
                const SizedBox(height: 16),
                _buildTimeline(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusHeader(String status, String id) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _statusColor(status).withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(status, style: TextStyle(fontWeight: FontWeight.bold, color: _statusColor(status), fontSize: 16)),
            ),
            const Spacer(),
            Text(id.length > 8 ? id.substring(0, 8) : id, style: TextStyle(fontSize: 11, color: Colors.grey[400])),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color ?? Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(color: color, fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    if (_timeline.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: Text('Timeline not available', style: TextStyle(color: Colors.grey))),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Timeline', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const Divider(),
            ...List.generate(_timeline.length, (i) {
              final entry = _timeline[i];
              final from = entry['from_status'] as String? ?? '';
              final to = entry['to_status'] as String? ?? '';
              final changedBy = entry['changed_by_role'] as String? ?? '';
              final reason = entry['reason'] as String? ?? '';
              final createdAt = entry['created_at'] as String? ?? '';
              final isLast = i == _timeline.length - 1;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Icon(Icons.circle, size: 12, color: _statusColor(to)),
                      if (!isLast) Container(width: 2, height: 40, color: Colors.grey[300]),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('$from → $to', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          if (reason.isNotEmpty) Text('Reason: $reason', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                          Text('By: $changedBy', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                          Text(_fmt(createdAt), style: TextStyle(fontSize: 10, color: Colors.grey[400])),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}
