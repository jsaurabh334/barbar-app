import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/barber_model.dart';
import '../../data/models/service_model.dart';
import '../bloc/booking/booking_bloc.dart';
import '../bloc/booking/booking_event.dart';
import '../bloc/booking/booking_state.dart';
import '../widgets/glass_card.dart';
import '../widgets/amenities_widget.dart';
import 'booking_confirmation_screen.dart';
import 'review_list_screen.dart';
import 'select_address_screen.dart';
import '../../domain/repositories/directory_repository.dart';

class BarberDetailScreen extends StatefulWidget {
  final BarberModel barber;

  const BarberDetailScreen({super.key, required this.barber});

  @override
  State<BarberDetailScreen> createState() => _BarberDetailScreenState();
}

class _BarberDetailScreenState extends State<BarberDetailScreen> {
  final List<String> _selectedServiceIds = [];
  DateTime _selectedDate = DateTime.now();
  String? _selectedTimeSlot;
  int _galleryIndex = 0;
  List<ServiceModel> _allServices = [];
  bool _isHomeService = false;
  String? _homeServiceAddressId;
  String? _homeServiceAddressLabel;

  List<Map<String, dynamic>> _staffList = [];
  bool _isLoadingStaff = true;
  String? _selectedStaffId;

  @override
  void initState() {
    super.initState();
    context.read<BookingBloc>().add(FetchServices(widget.barber.id));
    _fetchSlots();
    _fetchStaff();
  }

  void _fetchStaff() async {
    try {
      final repo = context.read<DirectoryRepository>();
      final staff = await repo.getBarberStaff(widget.barber.id);
      if (mounted) {
        setState(() {
          _staffList = staff;
          _isLoadingStaff = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingStaff = false;
        });
      }
    }
  }

  void _fetchSlots() {
    final dateStr = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
    context.read<BookingBloc>().add(FetchAvailableSlots(barberId: widget.barber.id, date: dateStr));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final allImages = [
      if (widget.barber.fullShopImage != null) widget.barber.fullShopImage!,
      ...widget.barber.fullShopImages,
    ];

    return Scaffold(
      body: Stack(
        children: [
          // Background image / gallery
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.35,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (allImages.isNotEmpty)
                  PageView.builder(
                    onPageChanged: (index) => setState(() => _galleryIndex = index),
                    itemCount: allImages.length,
                    itemBuilder: (context, index) => CachedNetworkImage(
                      imageUrl: allImages[index],
                      fit: BoxFit.cover,
                      errorWidget: (context, _, __) => Container(color: AppColors.surface),
                    ),
                  )
                else
                  CachedNetworkImage(
                    imageUrl: widget.barber.fullShopImage ?? '',
                    fit: BoxFit.cover,
                    errorWidget: (context, _, __) => Container(color: AppColors.surface),
                  ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.8),
                        Colors.black.withValues(alpha: 0.2),
                        Colors.transparent,
                        AppColors.background,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.4, 0.7, 1.0],
                    ),
                  ),
                ),
                if (allImages.length > 1)
                  Positioned(
                    bottom: 60,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        allImages.length,
                        (i) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: _galleryIndex == i ? 20 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: _galleryIndex == i ? AppColors.primary : Colors.white.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // App bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.black.withValues(alpha: 0.5),
                      child: IconButton(
                        icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    CircleAvatar(
                      backgroundColor: Colors.black.withValues(alpha: 0.5),
                      child: IconButton(
                        icon: const Icon(LucideIcons.share2, color: Colors.white),
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Content sheet
          Positioned.fill(
            top: size.height * 0.28,
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Shop Info
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.barber.shopName,
                                style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 24),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(LucideIcons.mapPin, size: 14, color: AppColors.textSecondary),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${widget.barber.address}, ${widget.barber.city}',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ReviewListScreen(
                                shopId: widget.barber.id,
                                shopName: widget.barber.shopName,
                              ),
                            ),
                          ),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.star, color: Colors.amber, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  widget.barber.rating.toStringAsFixed(1),
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber),
                                ),
                                const SizedBox(width: 2),
                                const Icon(Icons.chevron_right, color: Colors.amber, size: 14),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.barber.shopDescription ?? 'No description provided.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),

                    // Tags
                    if (widget.barber.tags != null && widget.barber.tags!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: widget.barber.tags!.map((tag) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            tag,
                            style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        )).toList(),
                      ),
                    ],

                    // Amenities
                    if (widget.barber.amenities != null && widget.barber.amenities!.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      AmenitiesWidget(amenities: widget.barber.amenities!),
                    ],

                    // Home Service Toggle
                    if (widget.barber.isHomeServiceAvailable) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _isHomeService ? LucideIcons.home : LucideIcons.store,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _isHomeService ? 'Home Service' : 'Visit Shop',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                      ),
                                      Text(
                                        _isHomeService
                                            ? 'We\'ll come to your address'
                                            : 'Visit us at our shop',
                                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: _isHomeService,
                                  activeTrackColor: AppColors.primary,
                                  onChanged: (val) => setState(() {
                                    _isHomeService = val;
                                    if (!val) {
                                      _homeServiceAddressId = null;
                                      _homeServiceAddressLabel = null;
                                    }
                                  }),
                                ),
                              ],
                            ),
                            if (_isHomeService) ...[
                              const Divider(height: 24, color: AppColors.border),
                              InkWell(
                                onTap: _pickHomeServiceAddress,
                                borderRadius: BorderRadius.circular(12),
                                child: Row(
                                  children: [
                                    const Icon(LucideIcons.mapPin, size: 18, color: AppColors.primary),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        _homeServiceAddressLabel ?? 'Select delivery address',
                                        style: TextStyle(
                                          fontWeight: _homeServiceAddressLabel != null ? FontWeight.w500 : FontWeight.normal,
                                          color: _homeServiceAddressLabel != null ? AppColors.textPrimary : AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                    const Icon(LucideIcons.chevronRight, size: 18, color: AppColors.textSecondary),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Radius: ${widget.barber.serviceRadiusKm} km • Base travel: ₹${widget.barber.baseTravelCharge.toInt()} + ₹${widget.barber.travelChargePerKm.toInt()}/km',
                                style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],

                    const Divider(height: 32, color: AppColors.border),

                    // Working Hours
                    Text(
                      'Working Hours',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    _buildWorkingHours(),
                    const Divider(height: 32, color: AppColors.border),

                    // Services
                    Text(
                      'Select Grooming Services',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    BlocConsumer<BookingBloc, BookingState>(
                      listener: (context, state) {
                        if (state is ServicesLoaded) {
                          setState(() => _allServices = state.services);
                        }
                      },
                      builder: (context, state) {
                        if (state is BookingLoading && _allServices.isEmpty) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20.0),
                              child: CircularProgressIndicator(color: AppColors.primary),
                            ),
                          );
                        }
                        if (_allServices.isNotEmpty) {
                          return Column(
                            children: _allServices.map((service) => _buildServiceTile(service)).toList(),
                          );
                        }
                        if (state is BookingFailure) {
                          return Text(state.error, style: const TextStyle(color: AppColors.error));
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    const Divider(height: 32, color: AppColors.border),

                    // Staff Selection
                    if (!_isLoadingStaff && _staffList.isNotEmpty) ...[
                      Text('Select Professional', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 12),
                      _buildStaffSelection(),
                      const Divider(height: 32, color: AppColors.border),
                    ],

                    // Date
                    Text(
                      'Select Date',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    _buildPickerButton(
                      icon: LucideIcons.calendar,
                      title: 'Date',
                      value: '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                      onTap: _pickDate,
                    ),
                    const SizedBox(height: 16),

                    // Time Slots
                    Text(
                      'Available Time Slots',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    _buildTimeSlots(),
                    const SizedBox(height: 16),

                    // Summary
                    if (_selectedServiceIds.isNotEmpty && _selectedTimeSlot != null) ...[
                      const Divider(height: 32, color: AppColors.border),
                      Text(
                        'Booking Summary',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      _buildSummary(),
                      const SizedBox(height: 24),
                    ],

                    // Book Button
                    BlocConsumer<BookingBloc, BookingState>(
                      listener: (context, state) {
                        if (state is BookingCreatedSuccess) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BookingConfirmationScreen(
                                booking: state.booking,
                                shopName: widget.barber.shopName,
                              ),
                            ),
                          );
                        } else if (state is BookingFailure) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(state.error.replaceAll('Exception: ', '')),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      builder: (context, state) {
                        final canBook = _selectedServiceIds.isNotEmpty && _selectedTimeSlot != null && (!_isHomeService || _homeServiceAddressId != null);

                        return ElevatedButton(
                          onPressed: canBook && state is! BookingLoading ? _confirmBooking : null,
                          child: state is BookingLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                                )
                              : const Text('Confirm Booking'),
                        );
                      },
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSlots() {
    return BlocBuilder<BookingBloc, BookingState>(
      builder: (context, state) {
        if (state is BookingLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        } else if (state is AvailableSlotsLoaded) {
          if (state.slots.isEmpty) {
            return const Text('No slots available for this date.', style: TextStyle(color: AppColors.textMuted));
          }
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: state.slots.map((slot) {
              final time = slot['time'] as String;
              bool available = slot['available'] as bool;
              final isSelected = _selectedTimeSlot == time;

              // Frontend filter to prevent booking past slots today
              final now = DateTime.now();
              if (_selectedDate.year == now.year &&
                  _selectedDate.month == now.month &&
                  _selectedDate.day == now.day) {
                final parts = time.split(':');
                if (parts.length == 2) {
                  final hour = int.tryParse(parts[0]) ?? 0;
                  final min = int.tryParse(parts[1]) ?? 0;
                  if (hour < now.hour || (hour == now.hour && min <= now.minute)) {
                    available = false;
                  }
                }
              }

              return InkWell(
                onTap: available ? () => setState(() => _selectedTimeSlot = time) : null,
                borderRadius: BorderRadius.circular(10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : available
                            ? AppColors.surface
                            : AppColors.surface.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : available
                              ? AppColors.border
                              : AppColors.border.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    time,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : available
                              ? AppColors.textPrimary
                              : AppColors.textMuted,
                      decoration: available ? null : TextDecoration.lineThrough,
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        } else if (state is BookingFailure) {
          return InkWell(
            onTap: _fetchSlots,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.refreshCw, size: 14, color: AppColors.primary),
                const SizedBox(width: 6),
                const Text('Retry', style: TextStyle(color: AppColors.primary)),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildSummary() {
    double total = 0;
    final selectedServices = _allServices.where((s) => _selectedServiceIds.contains(s.id)).toList();
    for (final s in selectedServices) {
      total += s.price;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _summaryRow(_isHomeService ? LucideIcons.home : LucideIcons.store, 'Type', _isHomeService ? 'Home Service' : 'Visit Shop'),
          const SizedBox(height: 8),
          _summaryRow(LucideIcons.store, 'Shop', widget.barber.shopName),
          const SizedBox(height: 8),
          _summaryRow(LucideIcons.calendar, 'Date', '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
          const SizedBox(height: 8),
          _summaryRow(LucideIcons.clock, 'Time', _selectedTimeSlot ?? ''),
          const SizedBox(height: 8),
          _summaryRow(LucideIcons.scissors, 'Services', selectedServices.map((s) => s.name).join(', ')),
          const SizedBox(height: 8),
          const Divider(height: 4, color: AppColors.border),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(LucideIcons.indianRupee, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text('Total', style: TextStyle(fontWeight: FontWeight.w600)),
              const Spacer(),
              Text(
                '₹${total.toInt()}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        SizedBox(
          width: 56,
          child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
        ),
      ],
    );
  }

  Widget _buildWorkingHours() {
    final dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final shortNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final businessDays = widget.barber.businessDays;
    final hasBusinessDays = businessDays != null && businessDays.isNotEmpty;

    return Column(
      children: List.generate(7, (i) {
        final dayLower = dayNames[i].toLowerCase();
        final isOpen = hasBusinessDays
            ? businessDays.any((d) {
                if (d is Map<String, dynamic>) {
                  return (d['day'] as String? ?? '').toLowerCase() == dayLower;
                }
                if (d is String) return d.toLowerCase() == dayLower;
                return false;
              })
            : (widget.barber.startTime?.isNotEmpty ?? false) &&
                (widget.barber.endTime?.isNotEmpty ?? false);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              SizedBox(
                width: 40,
                child: Text(
                  shortNames[i],
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isOpen ? AppColors.textPrimary : AppColors.textMuted,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  isOpen
                      ? '${widget.barber.startTime ?? '--'} - ${widget.barber.endTime ?? '--'}'
                      : 'Closed',
                  style: TextStyle(
                    color: isOpen ? AppColors.textSecondary : AppColors.error,
                  ),
                ),
              ),
              Icon(
                isOpen ? LucideIcons.checkCircle : LucideIcons.xCircle,
                size: 16,
                color: isOpen ? AppColors.success : AppColors.error,
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildServiceTile(ServiceModel service) {
    final isSelected = _selectedServiceIds.contains(service.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.border,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: CheckboxListTile(
        activeColor: AppColors.primary,
        checkColor: Colors.black,
        title: Text(
          service.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          '${service.durationMinutes} mins • ${service.description ?? ""}',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        secondary: Text(
          '₹${service.price.toInt()}',
          style: TextStyle(
            color: isSelected ? AppColors.primary : AppColors.textPrimary,
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
        value: isSelected,
        onChanged: (bool? val) {
          setState(() {
            if (val == true) {
              _selectedServiceIds.add(service.id);
            } else {
              _selectedServiceIds.remove(service.id);
            }
          });
        },
      ),
    );
  }

  Widget _buildPickerButton({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaffSelection() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildStaffCard(
            id: null,
            name: 'Any Available',
            imageUrl: null,
            isSelected: _selectedStaffId == null,
          ),
          ..._staffList.map((staff) {
            final user = staff['User'] ?? {};
            return _buildStaffCard(
              id: staff['ID'],
              name: user['first_name'] ?? 'Staff',
              imageUrl: user['profile_image_url'],
              isSelected: _selectedStaffId == staff['ID'],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStaffCard({
    required String? id,
    required String name,
    required String? imageUrl,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedStaffId = id;
          _selectedTimeSlot = null;
        });
        _fetchSlots();
      },
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surface,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.background,
              backgroundImage: imageUrl != null && imageUrl.isNotEmpty
                  ? CachedNetworkImageProvider(imageUrl)
                  : null,
              child: imageUrl == null || imageUrl.isEmpty
                  ? const Icon(LucideIcons.user, color: AppColors.textSecondary)
                  : null,
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              surface: AppColors.surface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _selectedTimeSlot = null;
      });
      _fetchSlots();
    }
  }

  Future<void> _pickHomeServiceAddress() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const SelectAddressScreen()),
    );
    if (result != null && result['id'] is String) {
      setState(() {
        _homeServiceAddressId = result['id'] as String;
        final label = result['label'] as String? ?? '';
        final line1 = result['line_1'] as String? ?? '';
        final city = result['city'] as String? ?? '';
        _homeServiceAddressLabel = '$label, $line1, $city';
      });
    }
  }

  void _confirmBooking() {
    if (_selectedTimeSlot == null) return;
    if (_isHomeService && _homeServiceAddressId == null) return;
    final parts = _selectedTimeSlot!.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    final dateStr = DateTime.utc(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      hour,
      minute,
    ).toIso8601String();

    context.read<BookingBloc>().add(
          CreateBooking(
            barberId: widget.barber.id,
            serviceIds: _selectedServiceIds,
            scheduledStart: dateStr,
            staffId: _selectedStaffId,
            isHomeService: _isHomeService,
            homeServiceAddressId: _homeServiceAddressId,
          ),
        );
  }
}
