import '../../domain/repositories/booking_repository.dart';
import '../datasources/remote/booking_remote_datasource.dart';
import '../models/booking_model.dart';
import '../models/service_model.dart';

class BookingRepositoryImpl implements BookingRepository {
  final BookingRemoteDataSource _remoteDataSource;

  List<BookingModel> _cachedBookings = [];

  static final List<ServiceModel> _mockServices = [
    ServiceModel(id: 's1', name: 'Premium Haircut', description: 'Fade, trim & styling', price: 350.0, durationMinutes: 30),
    ServiceModel(id: 's2', name: 'Beard Grooming', description: 'Beard trim, shape & oil', price: 200.0, durationMinutes: 20),
    ServiceModel(id: 's3', name: 'Hot Towel Shave', description: 'Straight razor shave & steam', price: 250.0, durationMinutes: 25),
    ServiceModel(id: 's4', name: 'Facial Therapy', description: 'Charcoal scrub & mask', price: 400.0, durationMinutes: 40),
  ];

  BookingRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<ServiceModel>> getServices(String barberId) async {
    try {
      return await _remoteDataSource.getServices(barberId);
    } catch (_) {
      return _mockServices;
    }
  }

  @override
  Future<BookingModel> createBooking({
    required String barberId,
    required List<String> serviceIds,
    required String scheduledStart,
  }) async {
    try {
      final data = await _remoteDataSource.createBooking(
        barberId: barberId,
        serviceIds: serviceIds,
        scheduledStart: scheduledStart,
      );
      final booking = BookingModel.fromJson(data);
      _cachedBookings.insert(0, booking);
      return booking;
    } catch (_) {
      final newBooking = BookingModel(
        id: 'mock-booking-${DateTime.now().millisecondsSinceEpoch}',
        barberId: barberId,
        customerId: 'current-user-uuid',
        status: 'pending',
        scheduledStart: scheduledStart,
        scheduledEnd: DateTime.parse(scheduledStart).add(const Duration(minutes: 30)).toIso8601String(),
        queuePosition: 4,
        estimatedWaitMinutes: 45,
        finalPrice: serviceIds.fold(0.0, (prev, id) {
          final service = _mockServices.firstWhere((s) => s.id == id, orElse: () => _mockServices.first);
          return prev + service.price;
        }),
        paymentStatus: 'pending',
        services: serviceIds.map((id) => _mockServices.firstWhere((s) => s.id == id)).toList(),
      );
      _cachedBookings.insert(0, newBooking);
      return newBooking;
    }
  }

  @override
  Future<Map<String, dynamic>> getQueuePosition(String bookingId) async {
    try {
      return await _remoteDataSource.getQueuePosition(bookingId);
    } catch (_) {
      return {
        'current_position': 3,
        'people_ahead': 2,
        'estimated_wait_min': 35,
      };
    }
  }

  @override
  Future<void> updateBookingStatus(String bookingId, String status) async {
    try {
      await _remoteDataSource.updateBookingStatus(bookingId, status);
    } catch (_) {
      _cachedBookings = _cachedBookings.map((b) {
        return b.id == bookingId ? b.copyWith(status: status) : b;
      }).toList();
    }
  }

  @override
  Future<List<BookingModel>> getAllBookings() async {
    try {
      final bookings = await _remoteDataSource.getCustomerBookings();
      _cachedBookings = bookings;
      return bookings;
    } catch (_) {
      if (_cachedBookings.isEmpty) {
        _cachedBookings = [
          BookingModel(
            id: 'booking-1', barberId: 'barber-1', customerId: 'cust-1',
            status: 'confirmed',
            scheduledStart: DateTime.now().add(const Duration(hours: 1)).toIso8601String(),
            scheduledEnd: DateTime.now().add(const Duration(hours: 1, minutes: 30)).toIso8601String(),
            queuePosition: 2, estimatedWaitMinutes: 20, finalPrice: 550.0,
            paymentStatus: 'success',
            services: [_mockServices[0], _mockServices[1]],
          ),
          BookingModel(
            id: 'booking-2', barberId: 'barber-1', customerId: 'cust-2',
            status: 'pending',
            scheduledStart: DateTime.now().add(const Duration(hours: 2)).toIso8601String(),
            scheduledEnd: DateTime.now().add(const Duration(hours: 2, minutes: 30)).toIso8601String(),
            queuePosition: 3, estimatedWaitMinutes: 50, finalPrice: 350.0,
            paymentStatus: 'pending',
            services: [_mockServices[0]],
          ),
        ];
      }
      return List.from(_cachedBookings);
    }
  }

  @override
  Future<List<BookingModel>> getBarberBookings() async {
    try {
      final bookings = await _remoteDataSource.getBarberBookings();
      _cachedBookings = bookings;
      return bookings;
    } catch (_) {
      // Return same cached fallback
      return getAllBookings();
    }
  }

  @override
  Future<void> payBooking(String bookingId, String method, String status, String reference) async {
    try {
      await _remoteDataSource.payBooking(bookingId, method, status, reference);
      _cachedBookings = _cachedBookings.map((b) {
        return b.id == bookingId ? b.copyWith(paymentStatus: status) : b;
      }).toList();
    } catch (_) {
      _cachedBookings = _cachedBookings.map((b) {
        return b.id == bookingId ? b.copyWith(paymentStatus: status) : b;
      }).toList();
    }
  }

  @override
  Future<Map<String, dynamic>> getBookingInvoice(String bookingId) async {
    try {
      return await _remoteDataSource.getBookingInvoice(bookingId);
    } catch (_) {
      // Mock data matching backend data structure
      final booking = _cachedBookings.firstWhere((b) => b.id == bookingId, orElse: () => _cachedBookings.first);
      return {
        'invoice_no': 'REC-${booking.id.substring(0, 8)}',
        'date': DateTime.now().toIso8601String(),
        'due_date': booking.scheduledStart,
        'customer_name': 'Premium Customer',
        'customer_email': 'customer@example.com',
        'customer_phone': '+91 9999999999',
        'items': booking.services.map((s) => {
          'name': s.name,
          'quantity': 1,
          'price': s.price,
          'total': s.price,
        }).toList(),
        'subtotal': booking.finalPrice,
        'tax': booking.finalPrice * 0.18,
        'discount': 0.0,
        'total': booking.finalPrice,
        'platform_name': 'Barbar App',
        'currency': 'INR',
        'status': booking.status,
        'notes': 'Thank you for your business!',
      };
    }
  }
}
