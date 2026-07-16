import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

class VendorRemoteDataSource {
  final ApiClient _apiClient;

  VendorRemoteDataSource(this._apiClient);

  // ==================== Profile ====================

  Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.post('/vendor/register', data: data);
      
      if (response.data is! Map) {
        throw Exception("API returned unexpected type: ${response.data.runtimeType}. Content: ${response.data}");
      }
      
      final respData = response.data as Map<String, dynamic>;
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          (respData['status'] == 'success' || respData['status'] == 'created')) {
        return respData['data'] as Map<String, dynamic>;
      }
      throw Exception(respData['error'] ?? 'Registration failed');
    } on DioException catch (e) {
      if (e.response?.data is Map) {
        throw Exception(e.response?.data['error'] ?? e.message);
      }
      throw Exception("Network Error: ${e.message}. Status: ${e.response?.statusCode}. Body: ${e.response?.data}");
    }
  }

  Future<Map<String, dynamic>> getProfile() async {
    final response = await _apiClient.dio.get('/vendor/profile');
    if (response.statusCode == 200 && response.data['status'] == 'success') {
      final data = response.data['data'] as Map<String, dynamic>;
      return data['vendor'] as Map<String, dynamic>;
    }
    throw Exception(response.data['error'] ?? 'Failed to fetch profile');
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    final response = await _apiClient.dio.put('/vendor/profile', data: data);
    if (response.statusCode == 200 && response.data['status'] == 'success') {
      final result = response.data['data'] as Map<String, dynamic>;
      return result['vendor'] as Map<String, dynamic>;
    }
    throw Exception(response.data['error'] ?? 'Failed to update profile');
  }

  Future<Map<String, dynamic>> getDashboard() async {
    final response = await _apiClient.dio.get('/vendor/dashboard');
    if (response.statusCode == 200 && response.data['status'] == 'success') {
      return response.data['data'] as Map<String, dynamic>;
    }
    throw Exception(response.data['error'] ?? 'Failed to fetch dashboard');
  }

  // ==================== Branches ====================

  Future<Map<String, dynamic>> createBranch(Map<String, dynamic> data) async {
    final response = await _apiClient.dio.post('/vendor/branches', data: data);
    if ((response.statusCode == 200 || response.statusCode == 201) &&
        (response.data['status'] == 'success' || response.data['status'] == 'created')) {
      return response.data['data'] as Map<String, dynamic>;
    }
    throw Exception(response.data['error'] ?? 'Failed to create branch');
  }

  Future<List<dynamic>> listBranches() async {
    final response = await _apiClient.dio.get('/vendor/branches');
    if (response.statusCode == 200 && response.data['status'] == 'success') {
      return (response.data['data'] as List<dynamic>?) ?? [];
    }
    throw Exception(response.data['error'] ?? 'Failed to fetch branches');
  }

  Future<Map<String, dynamic>> getBranch(String branchId) async {
    final response = await _apiClient.dio.get('/vendor/branches/$branchId');
    if (response.statusCode == 200 && response.data['status'] == 'success') {
      return response.data['data'] as Map<String, dynamic>;
    }
    throw Exception(response.data['error'] ?? 'Failed to fetch branch');
  }

  Future<Map<String, dynamic>> updateBranch(String branchId, Map<String, dynamic> data) async {
    final response = await _apiClient.dio.put('/vendor/branches/$branchId', data: data);
    if (response.statusCode == 200 && response.data['status'] == 'success') {
      return response.data['data'] as Map<String, dynamic>;
    }
    throw Exception(response.data['error'] ?? 'Failed to update branch');
  }

  Future<void> deleteBranch(String branchId) async {
    final response = await _apiClient.dio.delete('/vendor/branches/$branchId');
    if (response.statusCode != 200 || response.data['status'] != 'success') {
      throw Exception(response.data['error'] ?? 'Failed to delete branch');
    }
  }

  Future<void> setDefaultBranch(String branchId) async {
    final response = await _apiClient.dio.put('/vendor/branches/$branchId/default');
    if (response.statusCode != 200 || response.data['status'] != 'success') {
      throw Exception(response.data['error'] ?? 'Failed to set default branch');
    }
  }

  // ==================== Gallery ====================

  Future<Map<String, dynamic>> uploadImage(Map<String, dynamic> data) async {
    final response = await _apiClient.dio.post('/vendor/gallery', data: data);
    if ((response.statusCode == 200 || response.statusCode == 201) &&
        (response.data['status'] == 'success' || response.data['status'] == 'created')) {
      return response.data['data'] as Map<String, dynamic>;
    }
    throw Exception(response.data['error'] ?? 'Failed to upload image');
  }

  Future<List<dynamic>> listImages({String? branchId, String? imageType}) async {
    final params = <String, dynamic>{};
    if (branchId != null) params['branch_id'] = branchId;
    if (imageType != null) params['image_type'] = imageType;
    final response = await _apiClient.dio.get('/vendor/gallery', queryParameters: params);
    if (response.statusCode == 200 && response.data['status'] == 'success') {
      return (response.data['data'] as List<dynamic>?) ?? [];
    }
    throw Exception(response.data['error'] ?? 'Failed to fetch images');
  }

  Future<void> deleteImage(String imageId) async {
    final response = await _apiClient.dio.delete('/vendor/gallery/$imageId');
    if (response.statusCode != 200 || response.data['status'] != 'success') {
      throw Exception(response.data['error'] ?? 'Failed to delete image');
    }
  }

  Future<void> reorderImages(List<String> imageIds) async {
    final response = await _apiClient.dio.put('/vendor/gallery/reorder', data: {'image_ids': imageIds});
    if (response.statusCode != 200 || response.data['status'] != 'success') {
      throw Exception(response.data['error'] ?? 'Failed to reorder images');
    }
  }

  // ==================== Working Hours ====================

  Future<List<dynamic>> setWorkingHours(String branchId, List<Map<String, dynamic>> hours) async {
    final response = await _apiClient.dio.put('/vendor/branches/$branchId/hours', data: hours);
    if (response.statusCode == 200 && response.data['status'] == 'success') {
      return (response.data['data'] as List<dynamic>?) ?? [];
    }
    throw Exception(response.data['error'] ?? 'Failed to set working hours');
  }

  Future<List<dynamic>> getWorkingHours(String branchId) async {
    final response = await _apiClient.dio.get('/vendor/branches/$branchId/hours');
    if (response.statusCode == 200 && response.data['status'] == 'success') {
      return (response.data['data'] as List<dynamic>?) ?? [];
    }
    throw Exception(response.data['error'] ?? 'Failed to fetch working hours');
  }

  // ==================== Holidays ====================

  Future<Map<String, dynamic>> addHoliday(String branchId, Map<String, dynamic> data) async {
    final response = await _apiClient.dio.post('/vendor/branches/$branchId/holidays', data: data);
    if ((response.statusCode == 200 || response.statusCode == 201) &&
        (response.data['status'] == 'success' || response.data['status'] == 'created')) {
      return response.data['data'] as Map<String, dynamic>;
    }
    throw Exception(response.data['error'] ?? 'Failed to add holiday');
  }

  Future<List<dynamic>> listHolidays(String branchId) async {
    final response = await _apiClient.dio.get('/vendor/branches/$branchId/holidays');
    if (response.statusCode == 200 && response.data['status'] == 'success') {
      return (response.data['data'] as List<dynamic>?) ?? [];
    }
    throw Exception(response.data['error'] ?? 'Failed to fetch holidays');
  }

  Future<void> deleteHoliday(String branchId, String holidayId) async {
    final response = await _apiClient.dio.delete('/vendor/branches/$branchId/holidays/$holidayId');
    if (response.statusCode != 200 || response.data['status'] != 'success') {
      throw Exception(response.data['error'] ?? 'Failed to delete holiday');
    }
  }

  // ==================== Products ====================

  Future<List<dynamic>> listProducts() async {
    final response = await _apiClient.dio.get('/vendor/products');
    if (response.statusCode == 200 && response.data['status'] == 'success') {
      return (response.data['data'] as List<dynamic>?) ?? [];
    }
    throw Exception(response.data['error'] ?? 'Failed to fetch products');
  }

  Future<Map<String, dynamic>> createProduct(Map<String, dynamic> data) async {
    final response = await _apiClient.dio.post('/products/', data: data);
    if ((response.statusCode == 200 || response.statusCode == 201) &&
        (response.data['status'] == 'success' || response.data['status'] == 'created')) {
      return response.data['data'] as Map<String, dynamic>;
    }
    throw Exception(response.data['error'] ?? 'Failed to create product');
  }

  Future<Map<String, dynamic>> updateProduct(String productId, Map<String, dynamic> data) async {
    final response = await _apiClient.dio.put('/products/$productId', data: data);
    if (response.statusCode == 200 && response.data['status'] == 'success') {
      return response.data['data'] as Map<String, dynamic>;
    }
    throw Exception(response.data['error'] ?? 'Failed to update product');
  }

  Future<void> deleteProduct(String productId) async {
    final response = await _apiClient.dio.delete('/products/$productId');
    if (response.statusCode != 200 || response.data['status'] != 'success') {
      throw Exception(response.data['error'] ?? 'Failed to delete product');
    }
  }

  // ==================== Orders ====================

  Future<List<dynamic>> listOrders({String? status}) async {
    final params = <String, dynamic>{};
    if (status != null) params['status'] = status;
    final response = await _apiClient.dio.get('/vendor/orders', queryParameters: params);
    if (response.statusCode == 200 && response.data['status'] == 'success') {
      return (response.data['data'] as List<dynamic>?) ?? [];
    }
    throw Exception(response.data['error'] ?? 'Failed to fetch orders');
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    final response = await _apiClient.dio.put('/vendor/orders/$orderId/status', data: {'status': status});
    if (response.statusCode != 200 || response.data['status'] != 'success') {
      throw Exception(response.data['error'] ?? 'Failed to update order status');
    }
  }
}
