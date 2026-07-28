import 'package:barbar_app/presentation/bloc/admin/admin_bookings_bloc.dart';
import 'package:barbar_app/presentation/screens/admin/admin_booking_detail_screen.dart';
import 'package:barbar_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

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
      search: _searchController.text,
    ));
  }

  void _resetPage() {
    _currentPage = 1;
    _loadBookings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: BlocBuilder<AdminBookingsBloc, AdminBookingsState>(
              builder: (context, state) {
                if (state is AdminBookingsLoading && _currentPage == 1) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }
                if (state is AdminBookingsError && _currentPage == 1) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.alertCircle, color: AppColors.error, size: 48),
                        const SizedBox(height: 16),
                        Text(state.message, style: const TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.black),
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
                          Icon(LucideIcons.calendarX, color: AppColors.textMuted.withValues(alpha: 0.4), size: 64),
                          const SizedBox(height: 16),
                          const Text('No bookings found', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                        ],
                      ),
                    );
                  }
                  return RefreshIndicator(
                    color: Colors.black,
                    backgroundColor: AppColors.primary,
                    onRefresh: () async {
                      _currentPage = 1;
                      _loadBookings();
                    },
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: state.bookings.length + (state.hasReachedMax ? 0 : 1),
                      itemBuilder: (context, index) {
                        if (index >= state.bookings.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Search bookings by ID, Name...',
                hintStyle: TextStyle(color: AppColors.textMuted),
                prefixIcon: Icon(LucideIcons.search, color: AppColors.textSecondary, size: 20),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onSubmitted: (_) => _resetPage(),
            ),
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildDatePicker(),
                const SizedBox(width: 10),
                Container(height: 24, width: 1, color: AppColors.border),
                const SizedBox(width: 10),
                _buildStatusChip('All', null),
                ..._statuses.where((s) => s != null).map((s) => _buildStatusChip(s!.replaceAll('_', ' ').toUpperCase(), s)),
              ],
            ),
          ),
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.black : AppColors.textSecondary,
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
                  primary: AppColors.primary,
                  onPrimary: Colors.black,
                  surface: AppColors.cardBg,
                  onSurface: AppColors.textPrimary,
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: hasDate ? AppColors.primary.withValues(alpha: 0.2) : AppColors.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: hasDate ? AppColors.primary : AppColors.border),
        ),
        child: Row(
          children: [
            Icon(LucideIcons.calendar, size: 14, color: hasDate ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(
              hasDate ? _selectedDate! : 'Filter Date',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: hasDate ? AppColors.primary : AppColors.textSecondary,
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

  @override
  Widget build(BuildContext context) {
    final id = bookingData['id'] as String? ?? '';
    final shortId = id.length > 8 ? id.substring(0, 8) : id;
    final status = bookingData['status'] as String? ?? 'unknown';
    final customerName = _customerName(bookingData);
    final shopName = _shopName(bookingData);
    final scheduledStart = bookingData['scheduled_start'] as String? ?? '';
    final price = (bookingData['final_price'] as num?)?.toDouble() ?? (bookingData['total_price'] as num?)?.toDouble() ?? 0.0;
    
    final sColor = _statusColor(status);
    final initial = customerName.isNotEmpty && customerName != 'Customer' ? customerName[0].toUpperCase() : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          highlightColor: AppColors.primary.withValues(alpha: 0.05),
          splashColor: AppColors.primary.withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Avatar, Customer & Status Badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                      ),
                      alignment: Alignment.center,
                      child: initial != null
                          ? Text(
                              initial,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            )
                          : const Icon(LucideIcons.user, size: 20, color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customerName, 
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          if (shopName.isNotEmpty) 
                            Row(
                              children: [
                                const Icon(LucideIcons.store, size: 13, color: AppColors.primary),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    shopName, 
                                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
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
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: sColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: sColor.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        status.replaceAll('_', ' ').toUpperCase(), 
                        style: TextStyle(fontSize: 10, color: sColor, fontWeight: FontWeight.bold, letterSpacing: 0.5)
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Bottom Inner surface box: Date, ID & Price
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(LucideIcons.calendarClock, size: 14, color: AppColors.primary),
                                const SizedBox(width: 6),
                                Text(
                                  _formatDateTime(scheduledStart), 
                                  style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, fontWeight: FontWeight.w500)
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(LucideIcons.hash, size: 12, color: AppColors.textMuted),
                                const SizedBox(width: 4),
                                Text(
                                  shortId, 
                                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontFamily: 'monospace')
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '₹${price.toStringAsFixed(0)}', 
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary)
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _customerName(Map<String, dynamic> data) {
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

  String _shopName(Map<String, dynamic> data) {
    if (data['barber'] != null && data['barber'] is Map) {
      final m = data['barber'] as Map<String, dynamic>;
      final name = (m['shop_name'] ?? m['name']) as String?;
      if (name != null && name.trim().isNotEmpty) return name;
    }
    final sName = (data['shop_name'] ?? data['barber_shop_name']) as String?;
    if (sName != null && sName.trim().isNotEmpty) return sName;
    return '';
  }

  String _formatDateTime(String iso) {
    if (iso.isEmpty) return 'TBA';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
    } catch (_) {
      return iso;
    }
  }
}
