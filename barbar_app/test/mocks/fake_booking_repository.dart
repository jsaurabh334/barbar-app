import 'package:barbar_app/data/models/booking_model.dart';
import 'package:barbar_app/data/models/service_model.dart';
import 'package:barbar_app/domain/repositories/booking_repository.dart';

class FakeBookingRepository implements BookingRepository {
  final List<BookingModel> _bookings = [];
  bool shouldThrow = false;
  String? nextToken;
  String _validOtp = '123456';

  void addBooking(BookingModel booking) => _bookings.add(booking);
  void clear() => _bookings.clear();
  void setValidOtp(String otp) => _validOtp = otp;

  @override
  Future<List<ServiceModel>> getServices(String barberId) async {
    if (shouldThrow) throw Exception('Service error');
    return [];
  }

  @override
  Future<BookingModel> createBooking({
    required String barberId,
    required List<String> serviceIds,
    required String scheduledStart,
    String? staffId,
    bool isHomeService = false,
    String? homeServiceAddressId,
  }) async {
    if (shouldThrow) throw Exception('Creation error');
    final booking = BookingModel(
      id: 'new-booking-id',
      barberId: barberId,
      customerId: 'customer-1',
      status: 'confirmed',
      scheduledStart: scheduledStart,
      scheduledEnd: scheduledStart,
      queuePosition: 0,
      estimatedWaitMinutes: 0,
      finalPrice: 0,
      paymentStatus: 'pending',
    );
    _bookings.add(booking);
    return booking;
  }

  @override
  Future<Map<String, dynamic>> getQueuePosition(String bookingId) async {
    if (shouldThrow) throw Exception('Queue position error');
    return {'current_position': 1, 'people_ahead': 0, 'estimated_wait_min': 5};
  }

  @override
  Future<BookingModel> getBookingById(String bookingId) async {
    if (shouldThrow) throw Exception('Get booking error');
    return _bookings.firstWhere(
      (b) => b.id == bookingId,
      orElse: () => BookingModel(
        id: bookingId,
        barberId: 'barber-1',
        customerId: 'customer-1',
        status: 'confirmed',
        scheduledStart: '2026-07-28T10:00:00Z',
        scheduledEnd: '2026-07-28T11:00:00Z',
        queuePosition: 0,
        estimatedWaitMinutes: 0,
        finalPrice: 0,
        paymentStatus: 'pending',
      ),
    );
  }

  @override
  Future<void> cancelBooking(String bookingId, {String? reason}) async {
    if (shouldThrow) throw Exception('Cancel error');
  }

  @override
  Future<void> updateBookingStatus(String bookingId, String status) async {
    if (shouldThrow) throw Exception('Update error');
  }

  @override
  Future<List<BookingModel>> getBarberBookings() async {
    if (shouldThrow) throw Exception('Barber bookings error');
    return _bookings;
  }

  @override
  Future<List<BookingModel>> getAllBookings() async {
    if (shouldThrow) throw Exception('All bookings error');
    return _bookings;
  }

  @override
  Future<Map<String, dynamic>> initiateBookingPayment({
    required String bookingId,
    required String gateway,
  }) async {
    if (shouldThrow) throw Exception('Payment error');
    return {};
  }

  @override
  Future<void> verifyBookingPayment({
    required String paymentId,
    required String gateway,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    if (shouldThrow) throw Exception('Verify error');
  }

  @override
  Future<void> payBooking(String bookingId, String method, String status, String reference) async {
    if (shouldThrow) throw Exception('Pay error');
  }

  @override
  Future<Map<String, dynamic>> getBookingInvoice(String bookingId) async {
    if (shouldThrow) throw Exception('Invoice error');
    return {};
  }

  @override
  Future<List<Map<String, dynamic>>> getAvailableSlots(String barberId, String date, {String? serviceIds, String? staffId}) async {
    if (shouldThrow) throw Exception('Slots error');
    return [];
  }

  @override
  Future<List<BookingModel>> getHomeServiceRequests() async {
    if (shouldThrow) throw Exception('Home service error');
    return [];
  }

  @override
  Future<void> acceptHomeService(String bookingId) async {
    if (shouldThrow) throw Exception('Accept error');
  }

  @override
  Future<void> rejectHomeService(String bookingId, String reason) async {
    if (shouldThrow) throw Exception('Reject error');
  }

  @override
  Future<void> checkIn(String bookingId, String method, {String? token, double? lat, double? lng}) async {
    if (shouldThrow) throw Exception('Check-in error');
  }

  @override
  Future<void> imComing(String bookingId) async {
    if (shouldThrow) throw Exception('ImComing error');
  }

  @override
  Future<Map<String, dynamic>> getCallPermission(String bookingId) async {
    if (shouldThrow) throw Exception('Call permission error');
    return {
      'id': bookingId,
      'barber_id': 'barber-1',
      'customer_id': 'customer-1',
      'status': 'confirmed',
      'scheduled_start': '2026-07-28T10:00:00Z',
      'scheduled_end': '2026-07-28T11:00:00Z',
      'queue_position': 0,
      'estimated_wait_minutes': 0,
      'final_price': 0,
      'payment_status': 'pending',
      'can_call_shop': true,
      'can_call_customer': false,
      'shop_phone': '12******90',
      'customer_phone': '98******10',
    };
  }

  @override
  Future<Map<String, dynamic>> getTodayQueue({String? staffId}) async {
    if (shouldThrow) throw Exception('Today queue error');
    final now = DateTime.now().toIso8601String();
    return {
      'bookings': [
        {
          'id': 'serving-1',
          'barber_id': 'barber-1',
          'customer_id': 'customer-1',
          'status': 'in_progress',
          'scheduled_start': now,
          'scheduled_end': now,
          'queue_position': 1,
          'estimated_wait_minutes': 15,
          'final_price': 30,
          'payment_status': 'unpaid',
          'services': [],
        },
        {
          'id': 'waiting-1',
          'barber_id': 'barber-1',
          'customer_id': 'customer-2',
          'status': 'waiting',
          'scheduled_start': now,
          'scheduled_end': now,
          'queue_position': 2,
          'estimated_wait_minutes': 15,
          'final_price': 25,
          'payment_status': 'unpaid',
          'services': [],
        },
      ],
      'staff': [
        {'id': 'staff-1', 'name': 'John'},
        {'id': 'staff-2', 'name': 'Jane'},
      ],
    };
  }

  @override
  Future<void> skipCustomer(String bookingId) async {
    if (shouldThrow) throw Exception('Skip error');
  }

  @override
  Future<void> startService(String bookingId) async {
    if (shouldThrow) throw Exception('Start error');
  }

  @override
  Future<void> completeService(String bookingId) async {
    if (shouldThrow) throw Exception('Complete error');
  }

  @override
  Future<void> markNoShow(String bookingId) async {
    if (shouldThrow) throw Exception('No-show error');
  }

  @override
  Future<Map<String, dynamic>> requestCompletion(String bookingId) async {
    if (shouldThrow) throw Exception('Request completion error');
    _mutate(bookingId, (b) => b.copyWith(
      status: BookingModel.statusAwaitingCustomerConfirmation,
      endOtpGeneratedAt: DateTime.now().toIso8601String(),
      endOtpVerifiedAt: null,
    ));
    return {
      'booking_id': bookingId,
      'status': BookingModel.statusAwaitingCustomerConfirmation,
      'end_otp_generated_at': DateTime.now().toIso8601String(),
    };
  }

  @override
  Future<BookingModel> verifyCompletionOtp(String bookingId, String otp) async {
    if (shouldThrow) throw Exception('Verify OTP error');
    if (otp != _validOtp) throw Exception('Invalid OTP. 4 attempt(s) remaining.');
    final updated = _mutate(bookingId, (b) => b.copyWith(
      status: BookingModel.statusCompleted,
      endOtpVerifiedAt: DateTime.now().toIso8601String(),
    ));
    return updated;
  }

  @override
  Future<Map<String, dynamic>> regenerateCompletionOtp(String bookingId) async {
    if (shouldThrow) throw Exception('Regenerate OTP error');
    _mutate(bookingId, (b) => b.copyWith(
      endOtpGeneratedAt: DateTime.now().toIso8601String(),
      endOtpVerifiedAt: null,
    ));
    return {
      'booking_id': bookingId,
      'status': BookingModel.statusAwaitingCustomerConfirmation,
      'end_otp_generated_at': DateTime.now().toIso8601String(),
    };
  }

  @override
  Future<Map<String, dynamic>> resendCompletionOtp(String bookingId) async {
    if (shouldThrow) throw Exception('Resend OTP error');
    _mutate(bookingId, (b) => b.copyWith(
      endOtpGeneratedAt: DateTime.now().toIso8601String(),
      endOtpVerifiedAt: null,
    ));
    return {
      'booking_id': bookingId,
      'status': BookingModel.statusAwaitingCustomerConfirmation,
      'end_otp_generated_at': DateTime.now().toIso8601String(),
    };
  }

  @override
  Future<BookingModel> problemStillExists(String bookingId) async {
    if (shouldThrow) throw Exception('Problem still exists error');
    return _mutate(bookingId, (b) => b.copyWith(
      status: BookingModel.statusInProgress,
      endOtpGeneratedAt: null,
      endOtpVerifiedAt: null,
    ));
  }

  BookingModel _mutate(String bookingId, BookingModel Function(BookingModel) transform) {
    final index = _bookings.indexWhere((b) => b.id == bookingId);
    final current = index >= 0
        ? _bookings[index]
        : BookingModel(
            id: bookingId,
            barberId: 'barber-1',
            customerId: 'customer-1',
            status: BookingModel.statusInProgress,
            scheduledStart: '2026-07-28T10:00:00Z',
            scheduledEnd: '2026-07-28T11:00:00Z',
            queuePosition: 0,
            estimatedWaitMinutes: 0,
            finalPrice: 0,
            paymentStatus: 'pending',
            isHomeService: true,
          );
    final updated = transform(current);
    if (index >= 0) {
      _bookings[index] = updated;
    } else {
      _bookings.add(updated);
    }
    return updated;
  }
}
