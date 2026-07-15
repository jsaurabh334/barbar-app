import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/repositories/booking_repository.dart';
import '../widgets/glass_card.dart';

class InvoiceScreen extends StatefulWidget {
  final String bookingId;

  const InvoiceScreen({super.key, required this.bookingId});

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  Map<String, dynamic>? _invoiceData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchInvoice();
  }

  Future<void> _fetchInvoice() async {
    try {
      final repo = context.read<BookingRepository>();
      final data = await repo.getBookingInvoice(widget.bookingId);
      setState(() {
        _invoiceData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('INVOICE / RECEIPT'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _errorMessage != null
              ? Center(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.alertTriangle, color: AppColors.error, size: 48),
                          const SizedBox(height: 16),
                          Text(_errorMessage!, textAlign: TextAlign.center),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _isLoading = true;
                                _errorMessage = null;
                              });
                              _fetchInvoice();
                            },
                            child: const Text('RETRY'),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Icon(
                          LucideIcons.checkCircle2,
                          size: 64,
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Payment Successful!',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Invoice #${_invoiceData!['invoice_no']}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: 32),
                      
                      // Bill Info
                      GlassCard(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'BILL TO',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _invoiceData!['customer_name'] ?? 'Guest',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            if (_invoiceData!['customer_email'] != null && _invoiceData!['customer_email'] != '') ...[
                              const SizedBox(height: 4),
                              Text(_invoiceData!['customer_email'], style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                            ],
                            if (_invoiceData!['customer_phone'] != null && _invoiceData!['customer_phone'] != '') ...[
                              const SizedBox(height: 4),
                              Text(_invoiceData!['customer_phone'], style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                            ],
                            const Divider(height: 32, color: AppColors.border),
                            
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Date:', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                                Text(() { final d = (_invoiceData!['date'] ?? '').toString(); return d.length >= 10 ? d.substring(0, 10) : d; }(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Payment Status:', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    (_invoiceData!['status'] ?? 'paid').toString().toUpperCase(),
                                    style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 10),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Services breakdown
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'SERVICE BREAKDOWN',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                            ),
                            const Divider(height: 24, color: AppColors.border),
                            ...((_invoiceData!['items'] as List? ?? []).map((item) => Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(item['name']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text('₹${(item['price'] as num? ?? 0).toInt()}', style: const TextStyle(color: AppColors.textSecondary)),
                                ],
                              ),
                            ))),
                            const Divider(height: 24, color: AppColors.border),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Subtotal:', style: TextStyle(color: AppColors.textSecondary)),
                                Text('₹${(_invoiceData!['subtotal'] as num? ?? 0).toInt()}'),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('GST Tax (18%):', style: TextStyle(color: AppColors.textSecondary)),
                                Text('₹${(_invoiceData!['tax'] as num? ?? 0).toInt()}'),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Discount:', style: TextStyle(color: AppColors.textSecondary)),
                                Text('₹${(_invoiceData!['discount'] as num? ?? 0).toInt()}', style: const TextStyle(color: AppColors.success)),
                              ],
                            ),
                            const Divider(height: 24, color: AppColors.border),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Grand Total:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                Text(
                                  '₹${(_invoiceData!['total'] as num? ?? 0).toInt()}',
                                  style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primary, fontSize: 18),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      ElevatedButton(
                        onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                        child: const Text('BACK TO HOME'),
                      ),
                    ],
                  ),
                ),
    );
  }
}
