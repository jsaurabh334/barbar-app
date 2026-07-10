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

  Future<List<BookingModel>> getBarberBookings() async {
    final response = await _apiClient.dio.get('/barber/bookings');
    if (response.statusCode == 200 && (response.data['status'] == 'success' || response.data['status'] == 'created')) {
      final data = (response.data['data'] as List<dynamic>?) ?? [];
      return data.map((e) => BookingModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception(response.data['error'] ?? 'Failed to fetch barber bookings');
  }

  Future<List<BookingModel>> getCustomerBookings() async {
    final response = await _apiClient.dio.get('/bookings');
    if (response.statusCode == 200 && (response.data['status'] == 'success' || response.data['status'] == 'created')) {
      final data = (response.data['data'] as List<dynamic>?) ?? [];
      return data.map((e) => BookingModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception(response.data['error'] ?? 'Failed to fetch bookings');
  }

  Future<Map<String, dynamic>> getBookingInvoice(String bookingId) async {
    final response = await _apiClient.dio.get('/bookings/$bookingId/invoice');
    if (response.statusCode == 200 && (response.data['status'] == 'success' || response.data['status'] == 'created')) {
      return response.data['data'] as Map<String, dynamic>;
    }
    throw Exception(response.data['error'] ?? 'Failed to fetch invoice details');
  }

  Future<List<Map<String, dynamic>>> getAvailableSlots(String barberId, String date) async {
    final response = await _apiClient.dio.get('/public/barbers/$barberId/available-slots', queryParameters: {'date': date});
    if (response.statusCode == 200 && (response.data['status'] == 'success' || response.data['status'] == 'created')) {
      final data = (response.data['data'] as List<dynamic>?) ?? [];
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception(response.data['error'] ?? 'Failed to fetch available slots');
  }
}
