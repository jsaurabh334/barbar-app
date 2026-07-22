import 'package:barbar_app/presentation/bloc/admin/admin_orders_bloc.dart';
import 'package:barbar_app/presentation/screens/admin/admin_order_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});
  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  String? _selectedStatus;
  String? _selectedPaymentStatus;
  int _currentPage = 1;

  static const _statuses = [
    null, 'pending', 'accepted', 'packed', 'ready_for_pickup',
    'driver_assigned', 'picked_up', 'out_for_delivery', 'delivered', 'cancelled',
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
      page: _currentPage, status: _selectedStatus, paymentStatus: _selectedPaymentStatus, search: _searchController.text,
    ));
  }

  void _resetPage() { _currentPage = 1; _loadOrders(); }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildFilters(),
        Expanded(
          child: BlocBuilder<AdminOrdersBloc, AdminOrdersState>(
            builder: (context, state) {
              if (state is AdminOrdersLoading && _currentPage == 1) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is AdminOrdersError && _currentPage == 1) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Error: ${state.message}', style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 8),
                      ElevatedButton(onPressed: _resetPage, child: const Text('Retry')),
                    ],
                  ),
                );
              }
              if (state is AdminOrdersLoaded) {
                if (state.orders.isEmpty) return const Center(child: Text('No orders found'));
                return RefreshIndicator(
                  onRefresh: () async { _currentPage = 1; _loadOrders(); },
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(8),
                    itemCount: state.orders.length + (state.hasReachedMax ? 0 : 1),
                    itemBuilder: (context, index) {
                      if (index >= state.orders.length) {
                        return const Center(child: CircularProgressIndicator());
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
      padding: const EdgeInsets.all(8),
      color: Colors.grey[100],
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Search by order number...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onSubmitted: (_) => _resetPage(),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildStatusChip('All', null),
                ..._statuses.where((s) => s != null).map((s) => _buildStatusChip(s!, s)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, String? status) {
    final isSelected = _selectedStatus == status;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label, style: const TextStyle(fontSize: 11)),
        selected: isSelected,
        onSelected: (_) { setState(() => _selectedStatus = status); _resetPage(); },
      ),
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

  @override
  Widget build(BuildContext context) {
    final id = orderData['id'] as String? ?? '';
    final orderNumber = orderData['order_number'] as String? ?? '';
    final status = orderData['status'] as String? ?? 'unknown';
    final customerName = orderData['customer']?['full_name'] as String? ?? orderData['customer_name'] as String? ?? 'Guest';
    final vendorName = orderData['vendor']?['business_name'] as String? ?? '';
    final amount = (orderData['final_amount'] as num?)?.toDouble() ?? 0.0;
    final paymentStatus = orderData['payment_status'] as String? ?? '';
    final items = (orderData['items'] as List<dynamic>?) ?? [];
    final itemCount = items.fold<int>(0, (sum, i) => sum + ((i['quantity'] as num?)?.toInt() ?? 1));

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text('#$orderNumber', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _statusColor(status).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(status, style: TextStyle(fontSize: 11, color: _statusColor(status), fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(children: [
                Icon(Icons.person, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(customerName, style: const TextStyle(fontSize: 13)),
              ]),
              if (vendorName.isNotEmpty) Row(children: [
                Icon(Icons.store, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(vendorName, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ]),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.shopping_bag, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text('$itemCount items', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  const Spacer(),
                  Text('₹${amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: paymentStatus == 'paid' || paymentStatus == 'success' ? Colors.green.withOpacity(0.15) : Colors.orange.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(paymentStatus, style: TextStyle(fontSize: 10, color: paymentStatus == 'paid' || paymentStatus == 'success' ? Colors.green : Colors.orange)),
                  ),
                ],
              ),
              Text('ID: $id', style: TextStyle(fontSize: 10, color: Colors.grey[400])),
            ],
          ),
        ),
      ),
    );
  }
}
