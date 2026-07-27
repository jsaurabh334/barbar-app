import 'package:barbar_app/core/theme/app_theme.dart';
import 'package:barbar_app/core/utils/debouncer.dart';
import 'package:barbar_app/presentation/bloc/admin/admin_orders_bloc.dart';
import 'package:barbar_app/presentation/screens/admin/admin_order_detail_screen.dart';
import 'package:barbar_app/presentation/widgets/admin/admin_empty_state.dart';
import 'package:barbar_app/presentation/widgets/admin/admin_error_state.dart';
import 'package:barbar_app/presentation/widgets/admin/admin_loading_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});
  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  final _debouncer = Debouncer(milliseconds: 500);

  String? _selectedStatus;
  String? _selectedPaymentStatus;
  DateTimeRange? _selectedDateRange;
  int _currentPage = 1;

  static const _statuses = [
    null, 'pending', 'accepted', 'packed', 'ready_for_pickup',
    'driver_assigned', 'picked_up', 'out_for_delivery', 'delivered', 'cancelled',
  ];

  static const _paymentStatuses = [
    null, 'pending', 'paid', 'failed', 'refunded'
  ];

  @override
  void initState() {
    super.initState();
    _loadOrders();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final state = context.read<AdminOrdersBloc>().state;
      if (state is AdminOrdersLoaded && !state.hasReachedMax) {
        _currentPage++;
        _loadOrders();
      }
    }
  }

  void _loadOrders() {
    context.read<AdminOrdersBloc>().add(LoadOrders(
      page: _currentPage, 
      status: _selectedStatus, 
      paymentStatus: _selectedPaymentStatus, 
      search: _searchController.text,
      dateFrom: _selectedDateRange?.start.toIso8601String(),
      dateTo: _selectedDateRange?.end.toIso8601String(),
    ));
  }

  void _resetPage() { 
    _currentPage = 1; 
    _loadOrders(); 
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildFilters(),
        Expanded(
          child: BlocConsumer<AdminOrdersBloc, AdminOrdersState>(
            listener: (context, state) {
              if (state is AdminOrdersError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
                );
              }
            },
            builder: (context, state) {
              if (state is AdminOrdersLoading && _currentPage == 1) {
                return const AdminLoadingState();
              }
              if (state is AdminOrdersError && _currentPage == 1) {
                return AdminErrorState(message: state.message, onRetry: _resetPage);
              }
              if (state is AdminOrdersLoaded) {
                if (state.orders.isEmpty) {
                  return const AdminEmptyState(
                    icon: LucideIcons.shoppingBag,
                    title: 'No orders found',
                    subtitle: 'Try adjusting your filters or search query.',
                  );
                }
                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async { _resetPage(); },
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: state.orders.length + (state.hasReachedMax ? 0 : 1),
                    itemBuilder: (context, index) {
                      if (index >= state.orders.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                        );
                      }
                      return _OrderCard(
                        orderData: state.orders[index],
                        onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => BlocProvider.value(
                            value: context.read<AdminOrdersBloc>(),
                            child: AdminOrderDetailScreen(orderData: state.orders[index]),
                          ),
                        )),
                      );
                    },
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ],
    );
  }

    Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.black, // Dark theme match
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search orders...',
                hintStyle: TextStyle(color: Colors.grey[500]),
                prefixIcon: const Icon(LucideIcons.search, color: Colors.grey),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onChanged: (value) {
                _debouncer.run(() => _resetPage());
              },
            ),
          ),
          const SizedBox(width: 12),
          InkWell(
            onTap: _showFilterSheet,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (_selectedStatus != null || _selectedPaymentStatus != null || _selectedDateRange != null) ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                LucideIcons.listFilter,
                color: (_selectedStatus != null || _selectedPaymentStatus != null || _selectedDateRange != null) ? Colors.black : Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Filters', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                      IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Order Status', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildModalChip('All', null, true, setModalState),
                      ..._statuses.where((s) => s != null).map((s) => _buildModalChip(s!, s, true, setModalState)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('Payment Status', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildModalChip('All', null, false, setModalState),
                      ..._paymentStatuses.where((s) => s != null).map((s) => _buildModalChip(s!, s, false, setModalState)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Date Range', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
                      if (_selectedDateRange != null)
                        TextButton(
                          onPressed: () {
                            setModalState(() => _selectedDateRange = null);
                            setState(() {});
                          },
                          child: const Text('Clear', style: TextStyle(color: Colors.red)),
                        )
                    ],
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        initialDateRange: _selectedDateRange,
                        builder: (context, child) => Theme(
                          data: ThemeData.dark().copyWith(
                            colorScheme: const ColorScheme.dark(primary: AppColors.primary, onPrimary: Colors.black, surface: AppColors.surface, onSurface: Colors.white),
                          ),
                          child: child!,
                        ),
                      );
                      if (picked != null) {
                        setModalState(() => _selectedDateRange = picked);
                        setState(() {});
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey[800]!), borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.calendar, size: 20, color: Colors.grey),
                          const SizedBox(width: 12),
                          Text(_selectedDateRange == null ? 'Select Date Range' : '\/\/\ - \/\/', style: const TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 16)),
                      onPressed: () {
                        Navigator.pop(context);
                        _resetPage();
                      },
                      child: const Text('Apply Filters', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildModalChip(String label, String? status, bool isOrderStatus, StateSetter setModalState) {
    final isSelected = isOrderStatus ? _selectedStatus == status : _selectedPaymentStatus == status;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 12, color: isSelected ? Colors.black : Colors.white)),
      selected: isSelected,
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.cardBg,
      onSelected: (_) {
        setModalState(() {
          if (isOrderStatus) {
            _selectedStatus = status;
          } else {
            _selectedPaymentStatus = status;
          }
        });
        setState(() {});
      },
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> orderData;
  final VoidCallback onTap;
  const _OrderCard({required this.orderData, required this.onTap});

  Color _statusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'accepted': return Colors.blue;
      case 'packed': return Colors.indigo;
      case 'ready_for_pickup': return Colors.cyan;
      case 'driver_assigned': return Colors.lightBlue;
      case 'picked_up': return Colors.lime;
      case 'out_for_delivery': return Colors.amber;
      case 'delivered': return Colors.teal;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _getCustomerName(Map<String, dynamic> data) {
    if (data['customer'] != null && data['customer'] is Map) {
      final m = data['customer'] as Map<String, dynamic>;
      final name = (m['full_name'] ?? m['name'] ?? m['phone']) as String?;
      if (name != null && name.trim().isNotEmpty) return name;
    }
    if (data['user'] != null && data['user'] is Map) {
      final m = data['user'] as Map<String, dynamic>;
      final name = (m['full_name'] ?? m['name'] ?? m['phone']) as String?;
      if (name != null && name.trim().isNotEmpty) return name;
    }
    final cName = (data['customer_name'] ?? data['user_name'] ?? data['name']) as String?;
    if (cName != null && cName.trim().isNotEmpty) return cName;
    return 'Customer';
  }

  @override
  Widget build(BuildContext context) {
    final orderNumber = orderData['order_number'] as String? ?? '';
    final status = orderData['status'] as String? ?? 'unknown';
    final customerName = _getCustomerName(orderData);
    final vendorName = orderData['vendor']?['business_name'] as String? ?? '';
    final amount = (orderData['final_amount'] as num?)?.toDouble() ?? 0.0;
    final paymentStatus = orderData['payment_status'] as String? ?? '';
    final items = (orderData['items'] as List<dynamic>?) ?? [];
    final itemCount = items.fold<int>(0, (sum, i) => sum + ((i['quantity'] as num?)?.toInt() ?? 1));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text('#$orderNumber', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor(status).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(status.toUpperCase(), style: TextStyle(fontSize: 10, color: _statusColor(status), fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(children: [
                const Icon(LucideIcons.user, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(customerName, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
              ]),
              if (vendorName.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(children: [
                  Icon(LucideIcons.store, size: 16, color: Colors.grey[400]),
                  const SizedBox(width: 8),
                  Text(vendorName, style: TextStyle(fontSize: 14, color: Colors.grey[400])),
                ]),
              ],
              const SizedBox(height: 12),
              const Divider(color: AppColors.border),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(LucideIcons.shoppingBag, size: 16, color: Colors.grey[400]),
                  const SizedBox(width: 8),
                  Text('$itemCount items', style: TextStyle(fontSize: 14, color: Colors.grey[400])),
                  const Spacer(),
                  Text('₹${amount.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: paymentStatus == 'paid' || paymentStatus == 'success' ? Colors.green.withOpacity(0.15) : Colors.orange.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(paymentStatus.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: paymentStatus == 'paid' || paymentStatus == 'success' ? Colors.green : Colors.orange)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
