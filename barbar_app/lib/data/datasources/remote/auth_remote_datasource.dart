import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../models/user_model.dart';

class AuthRemoteDataSource {
  final ApiClient _apiClient;

  AuthRemoteDataSource(this._apiClient);

  Future<Map<String, dynamic>> register({
    required String fullName,
    required String phone,
    required String password,
    required String role,
    String? email,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/register',
        data: {
          'full_name': fullName,
          'phone': phone,
          'password': password,
          'role': role,
          if (email != null && email.isNotEmpty) 'email': email,
        },
      );
      
      if (response.statusCode == 201 && response.data['status'] == 'created') {
        return response.data['data'] as Map<String, dynamic>;
      }
      throw Exception(response.data['error'] ?? 'Registration failed');
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Connection error');
    }
  }

  Future<bool> sendOtp(String phone) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/otp/send',
        data: {'phone': phone},
      );
      return response.statusCode == 200 && response.data['status'] == 'success';
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Failed to send OTP');
    }
  }

  Future<Map<String, dynamic>> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/otp/verify',
        data: {'phone': phone, 'otp': otp},
      );

      if (response.statusCode == 200 && response.data['status'] == 'success') {
        return response.data['data'] as Map<String, dynamic>;
      }
      throw Exception(response.data['error'] ?? 'OTP verification failed');
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Verification error');
    }
  }

  Future<void> logout() async {
    try {
      await _apiClient.dio.post('/auth/logout');
    } catch (_) {
      // Allow local logout even if remote fails
    }
  }

  Future<UserModel> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.put('/auth/profile', data: data);
      if (response.statusCode == 200 && response.data['status'] == 'success') {
        return UserModel.fromJson(response.data['data'] as Map<String, dynamic>);
      }
      throw Exception(response.data['error'] ?? 'Profile update failed');
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Connection error');
    }
  }

  Future<String> uploadImage(String filePath) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
      });
      final response = await _apiClient.dio.post('/upload/image', data: formData);
      if ((response.statusCode == 200 || response.statusCode == 201) && 
          (response.data['status'] == 'success' || response.data['status'] == 'created')) {
        return response.data['data']['url'] as String;
      }
      throw Exception('Upload failed');
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Connection error during upload');
    }
  }
}
