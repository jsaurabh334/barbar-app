import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../models/booking_model.dart';
import '../../models/service_model.dart';

class BookingRemoteDataSource {
  final ApiClient _apiClient;

  BookingRemoteDataSource(this._apiClient);

  Future<List<ServiceModel>> getServices(String barberId) async {
    final response = await _apiClient.dio.get('/public/barbers/$barberId/services');
    if (response.statusCode == 200 && (response.data['status'] == 'success' || response.data['status'] == 'created')) {
      final data = (response.data['data'] as List<dynamic>?) ?? [];
      return data.map((e) => ServiceModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception(response.data['error'] ?? 'Failed to fetch services');
  }

  Future<Map<String, dynamic>> createBooking({
    required String barberId,
    required List<String> serviceIds,
    required String scheduledStart,
    String? staffId,
    bool isHomeService = false,
    String? homeServiceAddressId,
  }) async {
    try {
      final data = <String, dynamic>{
        'barber_id': barberId,
        'service_ids': serviceIds,
        'scheduled_start': scheduledStart,
        'is_home_service': isHomeService,
      };
      if (staffId != null) {
        data['staff_id'] = staffId;
      }
      if (homeServiceAddressId != null) {
        data['home_service_address_id'] = homeServiceAddressId;
      }
      final response = await _apiClient.dio.post('/bookings', data: data);
      if (response.statusCode == 201 && (response.data['status'] == 'success' || response.data['status'] == 'created')) {
        return response.data['data'] as Map<String, dynamic>;
      }
      throw Exception(response.data['error'] ?? 'Booking creation failed');
    } on DioException catch (e) {
      if (e.response?.data != null && e.response?.data is Map) {
        throw Exception(e.response!.data['error'] ?? 'Booking creation failed');
      }
      rethrow;
    }
  }

  Future<BookingModel> getBookingById(String bookingId) async {
    try {
      final response = await _apiClient.dio.get('/bookings/$bookingId');
      if (response.statusCode == 200 && (response.data['status'] == 'success' || response.data['status'] == 'created')) {
        return BookingModel.fromJson(response.data['data'] as Map<String, dynamic>);
      }
      throw Exception(response.data['error'] ?? 'Failed to fetch booking details');
    } on DioException catch (e) {
      throw Exception(_parseDioError(e, 'Failed to fetch booking details'));
    }
  }

  Future<Map<String, dynamic>> getQueuePosition(String bookingId) async {
    final response = await _apiClient.dio.get('/barber/queue/$bookingId');
    if (response.statusCode == 200 && (response.data['status'] == 'success' || response.data['status'] == 'created')) {
      return response.data['data'] as Map<String, dynamic>;
    }
    throw Exception(response.data['error'] ?? 'Failed to fetch queue position');
  }

  Future<void> cancelBooking(String bookingId, {String? reason}) async {
    final response = await _apiClient.dio.post(
      '/bookings/$bookingId/cancel',
      data: {'reason': reason ?? ''},
    );
    if (response.statusCode != 200 || (response.data['status'] != 'success' && response.data['status'] != 'created')) {
      throw Exception(response.data['error'] ?? 'Failed to cancel booking');
    }
  }

  Future<void> updateBookingStatus(String bookingId, String status) async {
    final response = await _apiClient.dio.put(
      '/barber/bookings/$bookingId/status',
      data: {'status': status},
    );
    if (response.statusCode != 200 || (response.data['status'] != 'success' && response.data['status'] != 'created')) {
      throw Exception(response.data['error'] ?? 'Failed to update status');
    }
  }

  Future<Map<String, dynamic>> initiateBookingPayment({
    required String bookingId,
    required String gateway,
  }) async {
    final response = await _apiClient.dio.post(
      '/payments/initiate',
      data: {
        'booking_id': bookingId,
        'gateway': gateway,
      },
    );
    if (response.statusCode == 200 && (response.data['status'] == 'success' || response.data['status'] == 'created')) {
      return response.data['data'] as Map<String, dynamic>;
    }
    throw Exception(response.data['error'] ?? 'Payment initiation failed');
  }

  Future<void> verifyBookingPayment({
    required String paymentId,
    required String gateway,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    final response = await _apiClient.dio.post(
      '/payments/verify',
      data: {
        'payment_id': paymentId,
        'gateway': gateway,
        'razorpay_order_id': razorpayOrderId,
        'razorpay_payment_id': razorpayPaymentId,
        'razorpay_signature': razorpaySignature,
      },
    );
    if (response.statusCode != 200 || (response.data['status'] != 'success' && response.data['status'] != 'created')) {
      throw Exception(response.data['error'] ?? 'Payment verification failed');
    }
  }

  Future<void> payBooking(String bookingId, String method, String status, String reference) async {
    final response = await _apiClient.dio.post(
      '/bookings/$bookingId/payment',
      data: {
        'method': method,
        'status': status,
        'reference': reference,
      },
    );
    if (response.statusCode != 200 || (response.data['status'] != 'success' && response.data['status'] != 'created')) {
      throw Exception(response.data['error'] ?? 'Payment registration failed');
    }
  }

  String _parseDioError(DioException e, String fallback) {
    if (e.response?.data != null && e.response?.data is Map) {
      final msg = e.response!.data['error'] ?? e.response!.data['message'];
      if (msg != null && msg.toString().isNotEmpty) return msg.toString();
    }
    if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
      return 'Connection timed out. Please check your network.';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Server is unreachable. Please try again later.';
    }
    return fallback;
  }

  Future<List<BookingModel>> getBarberBookings() async {
    try {
      final response = await _apiClient.dio.get('/barber/bookings');
      if (response.statusCode == 200 && (response.data['status'] == 'success' || response.data['status'] == 'created')) {
        final data = (response.data['data'] as List<dynamic>?) ?? [];
        return data.map((e) => BookingModel.fromJson(e as Map<String, dynamic>)).toList();
      }
      throw Exception(response.data['error'] ?? 'Failed to fetch barber bookings');
    } on DioException catch (e) {
      throw Exception(_parseDioError(e, 'Failed to fetch barber bookings'));
    }
  }

  Future<List<BookingModel>> getCustomerBookings() async {
    try {
      final response = await _apiClient.dio.get('/bookings');
      if (response.statusCode == 200 && (response.data['status'] == 'success' || response.data['status'] == 'created')) {
        final data = (response.data['data'] as List<dynamic>?) ?? [];
        return data.map((e) => BookingModel.fromJson(e as Map<String, dynamic>)).toList();
      }
      throw Exception(response.data['error'] ?? 'Failed to fetch bookings');
    } on DioException catch (e) {
      throw Exception(_parseDioError(e, 'Failed to fetch bookings'));
    }
  }

  Future<Map<String, dynamic>> getBookingInvoice(String bookingId) async {
    try {
      final response = await _apiClient.dio.get('/bookings/$bookingId/invoice');
      if (response.statusCode == 200 && (response.data['status'] == 'success' || response.data['status'] == 'created')) {
        return response.data['data'] as Map<String, dynamic>;
      }
      throw Exception(response.data['error'] ?? 'Failed to fetch invoice details');
    } on DioException catch (e) {
      throw Exception(_parseDioError(e, 'Failed to fetch invoice details'));
    }
  }

  Future<List<Map<String, dynamic>>> getAvailableSlots(String barberId, String date, {String? serviceIds, String? staffId}) async {
    final params = <String, dynamic>{'date': date};
    if (serviceIds != null && serviceIds.isNotEmpty) {
      params['service_ids'] = serviceIds;
    }
    if (staffId != null && staffId.isNotEmpty) {
      params['staff_id'] = staffId;
    }
    final response = await _apiClient.dio.get('/public/barbers/$barberId/available-slots', queryParameters: params);
    if (response.statusCode == 200 && (response.data['status'] == 'success' || response.data['status'] == 'created')) {
      final data = (response.data['data'] as List<dynamic>?) ?? [];
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception(response.data['error'] ?? 'Failed to fetch available slots');
  }

  Future<List<BookingModel>> getHomeServiceRequests() async {
    try {
      final response = await _apiClient.dio.get('/barber/home-service-requests');
      if (response.statusCode == 200 && (response.data['status'] == 'success' || response.data['status'] == 'created')) {
        final data = (response.data['data'] as List<dynamic>?) ?? [];
        return data.map((e) => BookingModel.fromJson(e as Map<String, dynamic>)).toList();
      }
      throw Exception(response.data['error'] ?? 'Failed to fetch home service requests');
    } on DioException catch (e) {
      throw Exception(_parseDioError(e, 'Failed to fetch home service requests'));
    }
  }

  Future<void> acceptHomeService(String bookingId) async {
    try {
      final response = await _apiClient.dio.post('/barber/home-service-requests/$bookingId/accept');
      if (response.statusCode != 200 || (response.data['status'] != 'success' && response.data['status'] != 'created')) {
        throw Exception(response.data['error'] ?? 'Failed to accept request');
      }
    } on DioException catch (e) {
      throw Exception(_parseDioError(e, 'Failed to accept home service request'));
    }
  }

  Future<void> rejectHomeService(String bookingId, String reason) async {
    try {
      final response = await _apiClient.dio.post(
        '/barber/home-service-requests/$bookingId/reject',
        data: {'reason': reason},
      );
      if (response.statusCode != 200 || (response.data['status'] != 'success' && response.data['status'] != 'created')) {
        throw Exception(response.data['error'] ?? 'Failed to reject request');
      }
    } on DioException catch (e) {
      throw Exception(_parseDioError(e, 'Failed to reject home service request'));
    }
  }

  Future<void> checkIn(String bookingId, String method, {String? token, double? lat, double? lng}) async {
    final data = <String, dynamic>{'method': method};
    if (token != null) data['token'] = token;
    if (lat != null) data['lat'] = lat;
    if (lng != null) data['lng'] = lng;
    final response = await _apiClient.dio.post('/bookings/$bookingId/check-in', data: data);
    if (response.statusCode != 200 || (response.data['status'] != 'success' && response.data['status'] != 'created')) {
      throw Exception(response.data['error'] ?? 'Check-in failed');
    }
  }

  Future<void> imComing(String bookingId) async {
    final response = await _apiClient.dio.post('/bookings/$bookingId/im-coming');
    if (response.statusCode != 200 || (response.data['status'] != 'success' && response.data['status'] != 'created')) {
      throw Exception(response.data['error'] ?? 'Failed to mark as coming');
    }
  }

  Future<Map<String, dynamic>> getCallPermission(String bookingId) async {
    final response = await _apiClient.dio.get('/bookings/$bookingId/call-permission');
    if (response.statusCode == 200 && (response.data['status'] == 'success' || response.data['status'] == 'created')) {
      return response.data['data'] as Map<String, dynamic>;
    }
    throw Exception(response.data['error'] ?? 'Failed to get call permission');
  }

  Future<Map<String, dynamic>> getTodayQueue({String? staffId}) async {
    final params = <String, dynamic>{};
    if (staffId != null) params['staff_id'] = staffId;
    final response = await _apiClient.dio.get('/barber/queue/today', queryParameters: params);
    if (response.statusCode == 200 && (response.data['status'] == 'success' || response.data['status'] == 'created')) {
      return response.data['data'] as Map<String, dynamic>;
    }
    throw Exception(response.data['error'] ?? 'Failed to fetch queue');
  }

  Future<void> skipCustomer(String bookingId) async {
    final response = await _apiClient.dio.put('/barber/queue/$bookingId/skip');
    if (response.statusCode != 200 || (response.data['status'] != 'success' && response.data['status'] != 'created')) {
      throw Exception(response.data['error'] ?? 'Failed to skip customer');
    }
  }

  Future<void> startService(String bookingId) async {
    final response = await _apiClient.dio.put('/barber/queue/$bookingId/start');
    if (response.statusCode != 200 || (response.data['status'] != 'success' && response.data['status'] != 'created')) {
      throw Exception(response.data['error'] ?? 'Failed to start service');
    }
  }

  Future<void> completeService(String bookingId) async {
    final response = await _apiClient.dio.put('/barber/queue/$bookingId/complete');
    if (response.statusCode != 200 || (response.data['status'] != 'success' && response.data['status'] != 'created')) {
      throw Exception(response.data['error'] ?? 'Failed to complete service');
    }
  }

  Future<void> markNoShow(String bookingId) async {
    final response = await _apiClient.dio.put('/barber/queue/$bookingId/no-show');
    if (response.statusCode != 200 || (response.data['status'] != 'success' && response.data['status'] != 'created')) {
      throw Exception(response.data['error'] ?? 'Failed to mark no show');
    }
  }

  Future<Map<String, dynamic>> requestCompletion(String bookingId) async {
    try {
      final response = await _apiClient.dio.post('/barber/home-service/$bookingId/request-completion');
      if (response.statusCode == 200 && (response.data['status'] == 'success' || response.data['status'] == 'created')) {
        return response.data['data'] as Map<String, dynamic>;
      }
      throw Exception(response.data['error'] ?? 'Failed to request completion');
    } on DioException catch (e) {
      throw Exception(_parseDioError(e, 'Failed to request completion'));
    }
  }

  Future<BookingModel> verifyCompletionOtp(String bookingId, String otp) async {
    try {
      final response = await _apiClient.dio.post(
        '/barber/home-service/$bookingId/verify-completion-otp',
        data: {'otp': otp},
      );
      if (response.statusCode == 200 && (response.data['status'] == 'success' || response.data['status'] == 'created')) {
        return BookingModel.fromJson(response.data['data'] as Map<String, dynamic>);
      }
      throw Exception(response.data['error'] ?? 'Failed to verify OTP');
    } on DioException catch (e) {
      throw Exception(_parseDioError(e, 'Failed to verify OTP'));
    }
  }

  Future<Map<String, dynamic>> regenerateCompletionOtp(String bookingId) async {
    try {
      final response = await _apiClient.dio.post('/barber/home-service/$bookingId/regenerate-completion-otp');
      if (response.statusCode == 200 && (response.data['status'] == 'success' || response.data['status'] == 'created')) {
        return response.data['data'] as Map<String, dynamic>;
      }
      throw Exception(response.data['error'] ?? 'Failed to regenerate OTP');
    } on DioException catch (e) {
      throw Exception(_parseDioError(e, 'Failed to regenerate OTP'));
    }
  }

  Future<Map<String, dynamic>> resendCompletionOtp(String bookingId) async {
    try {
      final response = await _apiClient.dio.post('/bookings/$bookingId/completion-otp/resend');
      if (response.statusCode == 200 && (response.data['status'] == 'success' || response.data['status'] == 'created')) {
        return response.data['data'] as Map<String, dynamic>;
      }
      throw Exception(response.data['error'] ?? 'Failed to resend OTP');
    } on DioException catch (e) {
      throw Exception(_parseDioError(e, 'Failed to resend OTP'));
    }
  }

  Future<BookingModel> problemStillExists(String bookingId) async {
    try {
      final response = await _apiClient.dio.post('/bookings/$bookingId/problem-still-exists');
      if (response.statusCode == 200 && (response.data['status'] == 'success' || response.data['status'] == 'created')) {
        return BookingModel.fromJson(response.data['data'] as Map<String, dynamic>);
      }
      throw Exception(response.data['error'] ?? 'Failed to report problem');
    } on DioException catch (e) {
      throw Exception(_parseDioError(e, 'Failed to report problem'));
    }
  }
}
