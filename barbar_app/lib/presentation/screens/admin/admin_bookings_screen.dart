import 'package:barbar_app/presentation/bloc/admin/admin_bookings_bloc.dart';
import 'package:barbar_app/presentation/screens/admin/admin_booking_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';

class AdminBookingsScreen extends StatefulWidget {
  const AdminBookingsScreen({super.key});

  @override
  State<AdminBookingsScreen> createState() => _AdminBookingsScreenState();
}

class _AdminBookingsScreenState extends State<AdminBookingsScreen> with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  String? _selectedStatus;
  String? _selectedDate;
  int _currentPage = 1;

  static const _statuses = [
    null,
    'pending',
    'confirmed',
    'in_progress',
    'completed',
    'cancelled',
    'no_show',
    'rescheduled',
  ];

  @override
  void initState() {
    super.initState();
    _loadBookings();
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
      final state = context.read<AdminBookingsBloc>().state;
      if (state is AdminBookingsLoaded && !state.hasReachedMax) {
        _currentPage++;
        _loadBookings();
      }
    }
  }

  void _loadBookings() {
    final date = _selectedDate;
    context.read<AdminBookingsBloc>().add(LoadBookings(
      page: _currentPage,
      status: _selectedStatus,
      date: date?.isEmpty == true ? null : date,
    ));
  }

  void _resetPage() {
    _currentPage = 1;
    _loadBookings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: BlocBuilder<AdminBookingsBloc, AdminBookingsState>(
              builder: (context, state) {
                if (state is AdminBookingsLoading && _currentPage == 1) {
                  return const Center(child: CircularProgressIndicator(color: Colors.white));
                }
                if (state is AdminBookingsError && _currentPage == 1) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.alertCircle, color: Colors.redAccent, size: 48),
                        const SizedBox(height: 16),
                        Text(state.message, style: const TextStyle(color: Colors.white70, fontSize: 16)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
                          onPressed: _resetPage, 
                          child: const Text('Retry')
                        ),
                      ],
                    ),
                  );
                }
                if (state is AdminBookingsLoaded) {
                  if (state.bookings.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.calendarX, color: Colors.white.withValues(alpha: 0.2), size: 64),
                          const SizedBox(height: 16),
                          const Text('No bookings found', style: TextStyle(color: Colors.white54, fontSize: 16)),
                        ],
                      ),
                    );
                  }
                  return RefreshIndicator(
                    color: Colors.black,
                    backgroundColor: Colors.white,
                    onRefresh: () async {
                      _currentPage = 1;
                      _loadBookings();
                    },
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: state.bookings.length + (state.hasReachedMax ? 0 : 1),
                      itemBuilder: (context, index) {
                        if (index >= state.bookings.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(child: CircularProgressIndicator(color: Colors.white)),
                          );
                        }
                        final bookingData = state.bookings[index];
                        return _BookingCard(
                          bookingData: bookingData,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BlocProvider.value(
                                  value: context.read<AdminBookingsBloc>(),
                                  child: AdminBookingDetailScreen(bookingData: bookingData),
                                ),
                              ),
                            );
                          },
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
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search bookings by ID, Name...',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                prefixIcon: Icon(LucideIcons.search, color: Colors.white.withValues(alpha: 0.5), size: 20),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onSubmitted: (_) => _resetPage(),
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildDatePicker(),
                const SizedBox(width: 12),
                Container(height: 30, width: 1, color: Colors.white.withValues(alpha: 0.1)),
                const SizedBox(width: 12),
                _buildStatusChip('All', null),
                ..._statuses.where((s) => s != null).map((s) => _buildStatusChip(s!.replaceAll('_', ' ').toUpperCase(), s)),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, String? status) {
    final isSelected = _selectedStatus == status;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedStatus = status);
        _resetPage();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.black : Colors.white70,
          ),
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    final hasDate = _selectedDate != null && _selectedDate!.isNotEmpty;
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 30)),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.dark(
                  primary: Colors.white,
                  onPrimary: Colors.black,
                  surface: Color(0xFF1E1E1E),
                  onSurface: Colors.white,
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          setState(() => _selectedDate = picked.toIso8601String().split('T')[0]);
          _resetPage();
        } else {
          setState(() => _selectedDate = null);
          _resetPage();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: hasDate ? Colors.white.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: hasDate ? Colors.transparent : Colors.white.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(LucideIcons.calendar, size: 14, color: hasDate ? Colors.white : Colors.white70),
            const SizedBox(width: 8),
            Text(
              hasDate ? _selectedDate! : 'Filter Date',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: hasDate ? Colors.white : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Map<String, dynamic> bookingData;
  final VoidCallback onTap;

  const _BookingCard({required this.bookingData, required this.onTap});

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return const Color(0xFFFFA726); // Orange
      case 'confirmed': return const Color(0xFF29B6F6); // Light Blue
      case 'in_progress': return const Color(0xFF66BB6A); // Green
      case 'completed': return const Color(0xFF26A69A); // Teal
      case 'cancelled': return const Color(0xFFEF5350); // Red
      case 'no_show': return const Color(0xFF8D6E63); // Brown
      case 'rescheduled': return const Color(0xFFAB47BC); // Purple
      default: return const Color(0xFFBDBDBD); // Grey
    }
  }

  @override
  Widget build(BuildContext context) {
    final id = bookingData['id'] as String? ?? '';
    final shortId = id.length > 8 ? id.substring(0, 8) : id;
    final status = bookingData['status'] as String? ?? 'unknown';
    final customerName = _customerName(bookingData);
    final shopName = _shopName(bookingData);
    final scheduledStart = bookingData['scheduled_start'] as String? ?? '';
    final price = (bookingData['final_price'] as num?)?.toDouble() ?? 0.0;
    
    final sColor = _statusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          highlightColor: Colors.white.withValues(alpha: 0.05),
          splashColor: Colors.white.withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Avatar, Name & Badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.primaries[customerName.length % Colors.primaries.length].withValues(alpha: 0.2),
                      child: Text(
                        customerName.isNotEmpty ? customerName[0].toUpperCase() : '?',
                        style: TextStyle(
                          color: Colors.primaries[customerName.length % Colors.primaries.length],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customerName, 
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.white, letterSpacing: 0.5),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          if (shopName.isNotEmpty) 
                            Row(
                              children: [
                                Icon(LucideIcons.store, size: 12, color: Colors.white.withValues(alpha: 0.5)),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    shopName, 
                                    style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: sColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: sColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        status.replaceAll('_', ' ').toUpperCase(), 
                        style: TextStyle(fontSize: 10, color: sColor, fontWeight: FontWeight.w700, letterSpacing: 0.5)
                      ),
                    ),
                  ],
                ),
                
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(color: Colors.white12, height: 1),
                ),
                
                // Bottom Row: Date, Price & ID
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(LucideIcons.calendarClock, size: 14, color: Colors.white.withValues(alpha: 0.6)),
                              const SizedBox(width: 6),
                              Text(
                                _formatDateTime(scheduledStart), 
                                style: const TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w500)
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(LucideIcons.hash, size: 12, color: Colors.white.withValues(alpha: 0.3)),
                              const SizedBox(width: 4),
                              Text(
                                shortId, 
                                style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.4), fontFamily: 'monospace')
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '₹${price.toStringAsFixed(0)}', 
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: Colors.white)
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _customerName(Map<String, dynamic> data) {
    if (data['customer'] != null && data['customer']['full_name'] != null) {
      return data['customer']['full_name'] as String;
    }
    return data['customer_name'] as String? ?? 'Guest';
  }

  String _shopName(Map<String, dynamic> data) {
    if (data['barber'] != null && data['barber']['shop_name'] != null) {
      return data['barber']['shop_name'] as String;
    }
    return data['shop_name'] as String? ?? '';
  }

  String _formatDateTime(String iso) {
    if (iso.isEmpty) return 'TBA';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}
