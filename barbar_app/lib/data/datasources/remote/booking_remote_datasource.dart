import '../../../core/network/api_client.dart';
import '../../models/booking_model.dart';
import '../../models/service_model.dart';

class BookingRemoteDataSource {
  final ApiClient _apiClient;

  BookingRemoteDataSource(this._apiClient);

  Future<List<ServiceModel>> getServices(String barberId) async {
    final response = await _apiClient.dio.get('/public/barbers/$barberId/services');
    if (response.statusCode == 200 && response.data['success'] == true) {
      final List<dynamic> data = response.data['data'];
      return data.map((e) => ServiceModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception(response.data['error'] ?? 'Failed to fetch services');
  }

  Future<Map<String, dynamic>> createBooking({
    required String barberId,
    required List<String> serviceIds,
    required String scheduledStart,
  }) async {
    final response = await _apiClient.dio.post(
      '/bookings',
      data: {
        'barber_id': barberId,
        'service_ids': serviceIds,
        'scheduled_start': scheduledStart,
      },
    );
    if (response.statusCode == 201 && response.data['success'] == true) {
      return response.data['data'] as Map<String, dynamic>;
    }
    throw Exception(response.data['error'] ?? 'Booking creation failed');
  }

  Future<Map<String, dynamic>> getQueuePosition(String bookingId) async {
    final response = await _apiClient.dio.get('/barber/queue/$bookingId');
    if (response.statusCode == 200 && response.data['success'] == true) {
      return response.data['data'] as Map<String, dynamic>;
    }
    throw Exception(response.data['error'] ?? 'Failed to fetch queue position');
  }

  Future<void> updateBookingStatus(String bookingId, String status) async {
    final response = await _apiClient.dio.put(
      '/barber/bookings/$bookingId/status',
      data: {'status': status},
    );
    if (response.statusCode != 200 || response.data['success'] != true) {
      throw Exception(response.data['error'] ?? 'Failed to update status');
    }
  }

  Future<List<BookingModel>> getCustomerBookings() async {
    final response = await _apiClient.dio.get('/bookings');
    if (response.statusCode == 200 && response.data['success'] == true) {
      final List<dynamic> data = response.data['data'];
      return data.map((e) => BookingModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception(response.data['error'] ?? 'Failed to fetch bookings');
  }
}
