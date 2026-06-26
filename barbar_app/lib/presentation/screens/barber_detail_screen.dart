import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/barber_model.dart';
import '../../data/models/service_model.dart';
import '../bloc/booking/booking_bloc.dart';
import '../bloc/booking/booking_event.dart';
import '../bloc/booking/booking_state.dart';
import '../widgets/glass_card.dart';

class BarberDetailScreen extends StatefulWidget {
  final BarberModel barber;

  const BarberDetailScreen({super.key, required this.barber});

  @override
  State<BarberDetailScreen> createState() => _BarberDetailScreenState();
}

class _BarberDetailScreenState extends State<BarberDetailScreen> {
  final List<String> _selectedServiceIds = [];
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = const TimeOfDay(hour: 10, minute: 0);

  @override
  void initState() {
    super.initState();
    // Load services list
    context.read<BookingBloc>().add(FetchServices(widget.barber.id));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Banner Image background
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.35,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  widget.barber.shopImage ?? '',
                  fit: BoxFit.cover,
                  errorBuilder: (context, _, __) => Container(color: AppColors.surface),
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
              ],
            ),
          ),

          // Safe area app bar
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

          // Sliding sheet content
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
                    // Barber Info
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
                        Container(
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
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.barber.shopDescription ?? 'No description provided.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const Divider(height: 32, color: AppColors.border),

                    // Services Section
                    Text(
                      'Select Grooming Services',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    BlocBuilder<BookingBloc, BookingState>(
                      builder: (context, state) {
                        if (state is BookingLoading) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20.0),
                              child: CircularProgressIndicator(color: AppColors.primary),
                            ),
                          );
                        } else if (state is ServicesLoaded) {
                          return Column(
                            children: state.services.map((service) => _buildServiceTile(service)).toList(),
                          );
                        } else if (state is BookingFailure) {
                          return Text(state.error, style: const TextStyle(color: AppColors.error));
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    const Divider(height: 32, color: AppColors.border),

                    // Date & Time Picker Layout
                    Text(
                      'Schedule Slots',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildPickerButton(
                            icon: LucideIcons.calendar,
                            title: 'Date',
                            value: '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                            onTap: _pickDate,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildPickerButton(
                            icon: LucideIcons.clock,
                            title: 'Time',
                            value: _selectedTime.format(context),
                            onTap: _pickTime,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),

                    // Checkout CTA Action
                    BlocConsumer<BookingBloc, BookingState>(
                      listener: (context, state) {
                        if (state is BookingCreatedSuccess) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Appointment confirmed successfully! Joined queue.'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                          Navigator.pop(context); // Go back to Home
                        }
                      },
                      builder: (context, state) {
                        final priceSum = _calculateTotalPrice();
                        
                        return ElevatedButton(
                          onPressed: _selectedServiceIds.isEmpty || state is BookingLoading
                              ? null
                              : _confirmBooking,
                          child: state is BookingLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('BOOK & JOIN QUEUE (${_selectedServiceIds.length} items)'),
                                    Text(
                                      '₹${priceSum.toInt()}',
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                                    ),
                                  ],
                                ),
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

  double _calculateTotalPrice() {
    double sum = 0;
    // Sum pricing dynamically
    final state = context.read<BookingBloc>().state;
    if (state is ServicesLoaded) {
      for (final id in _selectedServiceIds) {
        final s = state.services.firstWhere((element) => element.id == id);
        sum += s.price;
      }
    }
    return sum;
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
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _confirmBooking() {
    final dateStr = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    ).toIso8601String();

    context.read<BookingBloc>().add(
          CreateBooking(
            barberId: widget.barber.id,
            serviceIds: _selectedServiceIds,
            scheduledStart: dateStr,
          ),
        );
  }
}
