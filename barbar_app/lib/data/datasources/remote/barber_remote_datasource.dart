import 'dart:io';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

class BarberRemoteDataSource {
  final ApiClient _apiClient;

  BarberRemoteDataSource(this._apiClient);

  Future<Map<String, dynamic>> registerBarber(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.post('/barber/register', data: data);
      if (response.statusCode == 201 && (response.data['status'] == 'success' || response.data['status'] == 'created')) {
        return response.data['data'] as Map<String, dynamic>;
      }
      throw Exception(response.data['error'] ?? 'Failed to register barber shop');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['error'] ?? e.message ?? 'Unknown error');
    }
  }

  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await _apiClient.dio.get('/barber/profile');
      if (response.statusCode == 200 && (response.data['status'] == 'success' || response.data['status'] == 'created')) {
        return response.data['data'] as Map<String, dynamic>;
      }
      throw Exception(response.data['error'] ?? 'Failed to fetch profile');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['error'] ?? e.message ?? 'Unknown error');
    }
  }

  Future<Map<String, dynamic>> getDashboard() async {
    final response = await _apiClient.dio.get('/barber/dashboard');
    if (response.statusCode == 200 && (response.data['status'] == 'success' || response.data['status'] == 'created')) {
      return response.data['data'] as Map<String, dynamic>;
    }
    throw Exception(response.data['error'] ?? 'Failed to fetch dashboard');
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.put('/barber/profile', data: data);
      if (response.statusCode == 200 && (response.data['status'] == 'success' || response.data['status'] == 'created')) {
        return response.data['data'] as Map<String, dynamic>;
      }
      throw Exception(response.data['error'] ?? 'Failed to update profile');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['error'] ?? e.message ?? 'Unknown error');
    }
  }

  Future<List<String>> uploadShopImages(List<File> files) async {
    final formData = FormData();
    for (var f in files) {
      formData.files.add(MapEntry(
        'files',
        await MultipartFile.fromFile(f.path, filename: f.path.split('/').last),
      ));
    }
    try {
      final response = await _apiClient.dio.post(
        '/upload/images?dir=shop_images',
        data: formData,
      );
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          (response.data['status'] == 'success' || response.data['status'] == 'created')) {
        final list = response.data['data'] as List<dynamic>;
        return list.map((e) => e['url'] as String).toList();
      }
      throw Exception(response.data['error'] ?? 'Failed to upload images');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['error'] ?? e.message ?? 'Unknown error');
    }
  }

  Future<void> updateAvailability({required bool isAvailable, String? status}) async {
    final data = <String, dynamic>{'is_available': isAvailable};
    if (status != null) data['status'] = status;
    final response = await _apiClient.dio.put('/barber/availability', data: data);
    if (response.statusCode != 200 || (response.data['status'] != 'success' && response.data['status'] != 'created')) {
      throw Exception(response.data['error'] ?? 'Failed to update availability');
    }
  }

  Future<Map<String, dynamic>> getEarnings({String period = 'week'}) async {
    final response = await _apiClient.dio.get('/barber/earnings', queryParameters: {'period': period});
    if (response.statusCode == 200 && (response.data['status'] == 'success' || response.data['status'] == 'created')) {
      return response.data['data'] as Map<String, dynamic>;
    }
    throw Exception(response.data['error'] ?? 'Failed to fetch earnings');
  }

  Future<List<Map<String, dynamic>>> getWeeklySchedule() async {
    final response = await _apiClient.dio.get('/barber/availability/weekly');
    if (response.statusCode == 200 && (response.data['status'] == 'success' || response.data['status'] == 'created')) {
      final data = (response.data['data'] as List<dynamic>?) ?? [];
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception(response.data['error'] ?? 'Failed to fetch schedule');
  }

  Future<List<Map<String, dynamic>>> setWeeklySchedule(List<Map<String, dynamic>> schedule) async {
    final response = await _apiClient.dio.post('/barber/availability/weekly', data: schedule);
    if (response.statusCode == 200 && (response.data['status'] == 'success' || response.data['status'] == 'created')) {
      final data = (response.data['data'] as List<dynamic>?) ?? [];
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception(response.data['error'] ?? 'Failed to save schedule');
  }

  Future<void> addHoliday({required String date, required String reason}) async {
    final response = await _apiClient.dio.post('/barber/holidays', data: {'date': date, 'reason': reason});
    if (response.statusCode != 201 || (response.data['status'] != 'success' && response.data['status'] != 'created')) {
      throw Exception(response.data['error'] ?? 'Failed to add holiday');
    }
  }

  Future<List<Map<String, dynamic>>> listHolidays() async {
    final response = await _apiClient.dio.get('/barber/holidays');
    if (response.statusCode == 200 && (response.data['status'] == 'success' || response.data['status'] == 'created')) {
      final data = (response.data['data'] as List<dynamic>?) ?? [];
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception(response.data['error'] ?? 'Failed to fetch holidays');
  }

  Future<List<Map<String, dynamic>>> getBarberServices() async {
    final response = await _apiClient.dio.get('/barber/services');
    if (response.statusCode == 200 && (response.data['status'] == 'success' || response.data['status'] == 'created')) {
      final data = (response.data['data'] as List<dynamic>?) ?? [];
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception(response.data['error'] ?? 'Failed to fetch services');
  }

  Future<Map<String, dynamic>> addService(Map<String, dynamic> data) async {
    final response = await _apiClient.dio.post('/barber/services', data: data);
    if (response.statusCode == 201 && (response.data['status'] == 'success' || response.data['status'] == 'created')) {
      return response.data['data'] as Map<String, dynamic>;
    }
    throw Exception(response.data['error'] ?? 'Failed to add service');
  }

  Future<void> updateService(String serviceId, Map<String, dynamic> data) async {
    final response = await _apiClient.dio.put('/barber/services/$serviceId', data: data);
    if (response.statusCode != 200 || (response.data['status'] != 'success' && response.data['status'] != 'created')) {
      throw Exception(response.data['error'] ?? 'Failed to update service');
    }
  }

  Future<void> deleteService(String serviceId) async {
    final response = await _apiClient.dio.delete('/barber/services/$serviceId');
    if (response.statusCode != 200 || (response.data['status'] != 'success' && response.data['status'] != 'created')) {
      throw Exception(response.data['error'] ?? 'Failed to delete service');
    }
  }

  Future<List<Map<String, dynamic>>> getHomeServiceRequests() async {
    final response = await _apiClient.dio.get('/barber/home-service-requests');
    if (response.statusCode == 200 && (response.data['status'] == 'success' || response.data['status'] == 'created')) {
      final data = (response.data['data'] as List<dynamic>?) ?? [];
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception(response.data['error'] ?? 'Failed to fetch home service requests');
  }

  Future<void> acceptHomeService(String requestId) async {
    final response = await _apiClient.dio.post('/barber/home-service-requests/$requestId/accept');
    if (response.statusCode != 200 || (response.data['status'] != 'success' && response.data['status'] != 'created')) {
      throw Exception(response.data['error'] ?? 'Failed to accept home service');
    }
  }

  Future<void> rejectHomeService(String requestId) async {
    final response = await _apiClient.dio.post('/barber/home-service-requests/$requestId/reject');
    if (response.statusCode != 200 || (response.data['status'] != 'success' && response.data['status'] != 'created')) {
      throw Exception(response.data['error'] ?? 'Failed to reject home service');
    }
  }

  Future<void> uploadDocument(String docType, String docUrl) async {
    final response = await _apiClient.dio.post('/barber/documents', data: {'doc_type': docType, 'doc_url': docUrl});
    if (response.statusCode != 201 || (response.data['status'] != 'success' && response.data['status'] != 'created')) {
      throw Exception(response.data['error'] ?? 'Failed to upload document');
    }
  }

  Future<List<Map<String, dynamic>>> listDocuments() async {
    final response = await _apiClient.dio.get('/barber/documents');
    if (response.statusCode == 200 && (response.data['status'] == 'success' || response.data['status'] == 'created')) {
      final data = (response.data['data'] as List<dynamic>?) ?? [];
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception(response.data['error'] ?? 'Failed to fetch documents');
  }

  Future<void> replaceDocument(String docId, String docType, String docUrl) async {
    final response = await _apiClient.dio.put('/barber/documents/$docId', data: {'doc_type': docType, 'doc_url': docUrl});
    if (response.statusCode != 200 || (response.data['status'] != 'success' && response.data['status'] != 'created')) {
      throw Exception(response.data['error'] ?? 'Failed to replace document');
    }
  }
  Future<List<Map<String, dynamic>>> getStaff() async {
    final response = await _apiClient.dio.get('/barber/staff');
    if (response.statusCode == 200 && (response.data['status'] == 'success' || response.data['status'] == 'created')) {
      final data = (response.data['data'] as List<dynamic>?) ?? [];
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception(response.data['error'] ?? 'Failed to fetch staff');
  }

  Future<Map<String, dynamic>> addStaff(Map<String, dynamic> staffData) async {
    final response = await _apiClient.dio.post('/barber/staff', data: staffData);
    if (response.statusCode == 200 || response.statusCode == 201) {
      if (response.data['status'] == 'success' || response.data['status'] == 'created') {
        return response.data['data'] as Map<String, dynamic>;
      }
    }
    throw Exception(response.data['error'] ?? 'Failed to add staff');
  }

  Future<Map<String, dynamic>> updateStaff(String staffId, Map<String, dynamic> updates) async {
    final response = await _apiClient.dio.put('/barber/staff/$staffId', data: updates);
    if (response.statusCode == 200 && (response.data['status'] == 'success' || response.data['status'] == 'created')) {
      return response.data['data'] as Map<String, dynamic>;
    }
    throw Exception(response.data['error'] ?? 'Failed to update staff');
  }

  Future<void> archiveStaff(String staffId) async {
    final response = await _apiClient.dio.delete('/barber/staff/$staffId');
    if (response.statusCode != 200 || (response.data['status'] != 'success' && response.data['status'] != 'created')) {
      throw Exception(response.data['error'] ?? 'Failed to archive staff');
    }
  }
}
