import 'dart:convert';
import 'package:barbar_app/presentation/bloc/admin/admin_bookings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:barbar_app/core/theme/app_theme.dart';
import 'package:barbar_app/domain/repositories/admin_repository.dart';

class AdminBookingDetailScreen extends StatefulWidget {
  final Map<String, dynamic> bookingData;
  final bool showActions;

  const AdminBookingDetailScreen({super.key, required this.bookingData, this.showActions = true});

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
    final repo = context.read<AdminBookingsBloc>().adminRepository;
    try {
      final detail = await repo.getAdminBookingDetail(_booking['id'] as String);
      if (mounted) {
        setState(() => _booking = detail);
      }
    } catch (_) {}
    try {
      final timeline = await repo.getAdminBookingTimeline(_booking['id'] as String);
      if (mounted) {
        setState(() => _timeline = timeline);
      }
    } catch (_) {}
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending': return AppColors.warning;
      case 'confirmed': return AppColors.info;
      case 'in_progress': return AppColors.success;
      case 'completed': return Colors.teal;
      case 'cancelled': return AppColors.error;
      case 'no_show': return AppColors.textMuted;
      case 'rescheduled': return Colors.purple;
      default: return AppColors.textMuted;
    }
  }

  String _fmt(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }

  String _formatAddress(dynamic addressVal) {
    if (addressVal == null) return '';
    if (addressVal is Map<String, dynamic>) {
      return _formatAddressMap(addressVal);
    }
    if (addressVal is String && addressVal.isNotEmpty) {
      try {
        final decoded = jsonDecode(addressVal);
        if (decoded is Map<String, dynamic>) {
          return _formatAddressMap(decoded);
        }
        return addressVal;
      } catch (_) {
        return addressVal;
      }
    }
    return addressVal.toString();
  }

  String _formatAddressMap(Map<String, dynamic> addr) {
    final line1 = addr['line_1'] as String? ?? addr['street'] as String? ?? '';
    final city = addr['city'] as String? ?? '';
    final state = addr['state'] as String? ?? '';
    final pincode = addr['pincode'] as String? ?? addr['zip'] as String? ?? '';
    final parts = [
      if (line1.isNotEmpty) line1,
      if (city.isNotEmpty) city,
      if (state.isNotEmpty) state,
      if (pincode.isNotEmpty) pincode,
    ];
    return parts.join(', ');
  }

  Future<void> _showCancelDialog() async {
    final reasonController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: const Text('Cancel Booking', style: TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: reasonController,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            hintText: 'Enter cancellation reason',
            hintStyle: TextStyle(color: AppColors.textMuted),
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Back', style: TextStyle(color: AppColors.textSecondary))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, reasonController.text),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
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
        backgroundColor: AppColors.cardBg,
        title: const Text('Reschedule Booking', style: TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: dateController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(labelText: 'New Date', hintText: 'YYYY-MM-DD', labelStyle: TextStyle(color: AppColors.textSecondary)),
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
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(labelText: 'New Time', hintText: 'HH:MM (24h)', labelStyle: TextStyle(color: AppColors.textSecondary)),
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
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Back', style: TextStyle(color: AppColors.textSecondary))),
          ElevatedButton(
            onPressed: () {
              if (dateController.text.isNotEmpty && timeController.text.isNotEmpty) {
                Navigator.pop(ctx, {'date': dateController.text, 'time': timeController.text});
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.black),
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
    final homeAddress = _formatAddress(_booking['home_service_address']);
    final services = (_booking['services'] as List<dynamic>?) ?? [];

    return BlocListener<AdminBookingsBloc, AdminBookingsState>(
      listener: (context, state) {
        if (state is AdminBookingActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
          Navigator.pop(context, true);
        } else if (state is AdminBookingsError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: AppColors.error));
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          title: const Text('Booking Detail', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
          actions: [
            if (status != 'cancelled' && status != 'completed')
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: AppColors.textPrimary),
                color: AppColors.cardBg,
                onSelected: (v) {
                  if (v == 'cancel') _showCancelDialog();
                  if (v == 'reschedule') _showRescheduleDialog();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'cancel', child: ListTile(leading: Icon(Icons.cancel, color: AppColors.error), title: Text('Cancel', style: TextStyle(color: AppColors.textPrimary)))),
                  const PopupMenuItem(value: 'reschedule', child: ListTile(leading: Icon(Icons.schedule, color: AppColors.primary), title: Text('Reschedule', style: TextStyle(color: AppColors.textPrimary)))),
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
                const SizedBox(height: 14),
                _buildSection(
                  'Customer',
                  [
                    _infoRow(Icons.person, customerName),
                    if (customerPhone.isNotEmpty) _infoRow(Icons.phone, customerPhone),
                  ],
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 14),
                _buildSection(
                  'Shop',
                  [
                    _infoRow(Icons.store, shopName),
                    if (barberAddress.isNotEmpty) _infoRow(Icons.location_on, barberAddress),
                  ],
                  icon: Icons.storefront,
                ),
                const SizedBox(height: 14),
                _buildSection(
                  'Schedule',
                  [
                    _infoRow(Icons.play_arrow, _fmt(scheduledStart), label: 'Start:'),
                    _infoRow(Icons.stop, _fmt(scheduledEnd), label: 'End:'),
                    if (isHomeService) _infoRow(Icons.home, homeAddress, label: 'Address:'),
                  ],
                  icon: Icons.calendar_today,
                ),
                const SizedBox(height: 14),
                if (services.isNotEmpty)
                  _buildSection(
                    'Services',
                    services.map<Widget>((s) {
                      final name = s['service_name'] as String? ?? s['name'] as String? ?? '';
                      final svcPrice = (s['total_price'] as num?)?.toDouble() ?? (s['price'] as num?)?.toDouble() ?? 0.0;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.content_cut, size: 18, color: AppColors.primary),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500, fontSize: 14),
                              ),
                            ),
                            Text(
                              '₹${svcPrice.toStringAsFixed(0)}',
                              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    icon: Icons.design_services,
                  ),
                const SizedBox(height: 14),
                _buildSection(
                  'Payment',
                  [
                    _infoRow(Icons.currency_rupee, '₹${totalPrice.toStringAsFixed(2)}', label: 'Total:'),
                    if (discount > 0) _infoRow(Icons.discount, '-₹${discount.toStringAsFixed(2)}', label: 'Discount:', color: AppColors.error),
                    _infoRow(Icons.payments, '₹${price.toStringAsFixed(2)}', label: 'Final Amount:', color: AppColors.primary),
                    _infoRow(Icons.check_circle_outline, paymentStatus.toUpperCase(), label: 'Status:'),
                    if (paymentMethod.isNotEmpty) _infoRow(Icons.credit_card, paymentMethod, label: 'Method:'),
                  ],
                  icon: Icons.account_balance_wallet_outlined,
                ),
                if (cancellationReason != null && cancellationReason.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _buildSection(
                    'Cancellation',
                    [
                      _infoRow(Icons.info_outline, cancellationReason, color: AppColors.error),
                    ],
                    icon: Icons.cancel_outlined,
                  ),
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
    final sColor = _statusColor(status);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: sColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: sColor.withOpacity(0.4)),
            ),
            child: Text(
              status.toUpperCase(),
              style: TextStyle(fontWeight: FontWeight.bold, color: sColor, fontSize: 13, letterSpacing: 0.5),
            ),
          ),
          const Spacer(),
          Text(
            '#${id.length > 8 ? id.substring(0, 8) : id}',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children, {IconData? icon}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
              ],
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, {Color? color, String? label}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color ?? AppColors.textSecondary),
          const SizedBox(width: 10),
          if (label != null) ...[
            Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color ?? AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    if (_timeline.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        padding: const EdgeInsets.all(16),
        child: const Center(
          child: Text('Timeline not available', style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.history, size: 18, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Timeline', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 14),
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
                    if (!isLast) Container(width: 2, height: 36, color: AppColors.border),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$from → $to', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary)),
                        if (reason.isNotEmpty) Text('Reason: $reason', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        Text('By: $changedBy', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                        Text(_fmt(createdAt), style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}
