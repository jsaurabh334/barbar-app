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

  // ==================== Warehouses ====================

  Future<Map<String, dynamic>> createWarehouse(Map<String, dynamic> data) async {
    final response = await _apiClient.dio.post('/vendor/warehouses', data: data);
    if ((response.statusCode == 200 || response.statusCode == 201) &&
        (response.data['status'] == 'success' || response.data['status'] == 'created')) {
      return response.data['data'] as Map<String, dynamic>;
    }
    throw Exception(response.data['error'] ?? 'Failed to create warehouse');
  }

  Future<List<dynamic>> listWarehouses() async {
    final response = await _apiClient.dio.get('/vendor/warehouses');
    if (response.statusCode == 200 && response.data['status'] == 'success') {
      return (response.data['data'] as List<dynamic>?) ?? [];
    }
    throw Exception(response.data['error'] ?? 'Failed to fetch warehouses');
  }

  Future<Map<String, dynamic>> getWarehouse(String warehouseId) async {
    final response = await _apiClient.dio.get('/vendor/warehouses/$warehouseId');
    if (response.statusCode == 200 && response.data['status'] == 'success') {
      return response.data['data'] as Map<String, dynamic>;
    }
    throw Exception(response.data['error'] ?? 'Failed to fetch warehouse');
  }

  Future<Map<String, dynamic>> updateWarehouse(String warehouseId, Map<String, dynamic> data) async {
    final response = await _apiClient.dio.put('/vendor/warehouses/$warehouseId', data: data);
    if (response.statusCode == 200 && response.data['status'] == 'success') {
      return response.data['data'] as Map<String, dynamic>;
    }
    throw Exception(response.data['error'] ?? 'Failed to update warehouse');
  }

  Future<void> deleteWarehouse(String warehouseId) async {
    final response = await _apiClient.dio.delete('/vendor/warehouses/$warehouseId');
    if (response.statusCode != 200 || response.data['status'] != 'success') {
      throw Exception(response.data['error'] ?? 'Failed to delete warehouse');
    }
  }

  Future<void> setDefaultWarehouse(String warehouseId) async {
    final response = await _apiClient.dio.put('/vendor/warehouses/$warehouseId/default');
    if (response.statusCode != 200 || response.data['status'] != 'success') {
      throw Exception(response.data['error'] ?? 'Failed to set default warehouse');
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

  Future<Map<String, dynamic>> getOrderById(String orderId) async {
    final response = await _apiClient.dio.get('/orders/$orderId');
    if (response.statusCode == 200 && response.data['status'] == 'success') {
      return response.data['data'] as Map<String, dynamic>;
    }
    throw Exception(response.data['error'] ?? 'Failed to fetch order');
  }

  Future<Map<String, dynamic>> acceptOrder(String orderId) async {
    final response = await _apiClient.dio.put('/vendor/orders/$orderId/accept');
    if (response.statusCode == 200 && response.data['status'] == 'success') {
      return response.data['data'] as Map<String, dynamic>;
    }
    throw Exception(response.data['error'] ?? 'Failed to accept order');
  }

  Future<Map<String, dynamic>> rejectOrder(String orderId, {String? reason}) async {
    final data = <String, dynamic>{};
    if (reason != null) data['reason'] = reason;
    final response = await _apiClient.dio.put('/vendor/orders/$orderId/reject', data: data);
    if (response.statusCode == 200 && response.data['status'] == 'success') {
      return response.data['data'] as Map<String, dynamic>;
    }
    throw Exception(response.data['error'] ?? 'Failed to reject order');
  }

  Future<Map<String, dynamic>> packOrder(String orderId) async {
    final response = await _apiClient.dio.put('/vendor/orders/$orderId/pack');
    if (response.statusCode == 200 && response.data['status'] == 'success') {
      return response.data['data'] as Map<String, dynamic>;
    }
    throw Exception(response.data['error'] ?? 'Failed to pack order');
  }

  Future<Map<String, dynamic>> readyForPickup(String orderId) async {
    final response = await _apiClient.dio.put('/vendor/orders/$orderId/ready-for-pickup');
    if (response.statusCode == 200 && response.data['status'] == 'success') {
      return response.data['data'] as Map<String, dynamic>;
    }
    throw Exception(response.data['error'] ?? 'Failed to set order ready for pickup');
  }

  // ==================== Delivery ====================

  Future<Map<String, dynamic>> getOrderDeliveryInfo(String orderId) async {
    final response = await _apiClient.dio.get('/vendor/orders/$orderId/delivery');
    if (response.statusCode == 200 && response.data['status'] == 'success') {
      return response.data['data'] as Map<String, dynamic>;
    }
    throw Exception(response.data['error'] ?? 'Failed to fetch delivery info');
  }

  // ==================== Brands ====================

  Future<List<dynamic>> getBrands() async {
    final response = await _apiClient.dio.get('/vendor/brands');
    if (response.statusCode == 200 && response.data['status'] == 'success') {
      return (response.data['data'] as List<dynamic>?) ?? [];
    }
    throw Exception(response.data['error'] ?? 'Failed to fetch brands');
  }

  Future<Map<String, dynamic>> createBrand(Map<String, dynamic> data) async {
    final response = await _apiClient.dio.post('/vendor/brands', data: data);
    if ((response.statusCode == 200 || response.statusCode == 201) &&
        (response.data['status'] == 'success' || response.data['status'] == 'created')) {
      return response.data['data'] as Map<String, dynamic>;
    }
    throw Exception(response.data['error'] ?? 'Failed to create brand');
  }

  Future<Map<String, dynamic>> updateBrand(String id, Map<String, dynamic> data) async {
    final response = await _apiClient.dio.put('/vendor/brands/$id', data: data);
    if (response.statusCode == 200 && response.data['status'] == 'success') {
      return response.data['data'] as Map<String, dynamic>;
    }
    throw Exception(response.data['error'] ?? 'Failed to update brand');
  }

  Future<void> deleteBrand(String id) async {
    final response = await _apiClient.dio.delete('/vendor/brands/$id');
    if (response.statusCode != 200 || response.data['status'] != 'success') {
      throw Exception(response.data['error'] ?? 'Failed to delete brand');
    }
  }

  // ==================== Product Images ====================

  Future<List<dynamic>> uploadProductImages(String productId, List<String> filePaths) async {
    final formData = FormData.fromMap({
      'images': await Future.wait(
        filePaths.map((path) async => await MultipartFile.fromFile(path)),
      ),
    });
    final response = await _apiClient.dio.post(
      '/products/$productId/images',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    if ((response.statusCode == 200 || response.statusCode == 201) &&
        (response.data['status'] == 'success' || response.data['status'] == 'created')) {
      final data = response.data['data'] as Map<String, dynamic>;
      return (data['images'] as List<dynamic>?) ?? [];
    }
    throw Exception(response.data['error'] ?? 'Failed to upload product images');
  }

  Future<List<dynamic>> listProductImages(String productId) async {
    final response = await _apiClient.dio.get('/products/$productId/images');
    if (response.statusCode == 200 && response.data['status'] == 'success') {
      return (response.data['data'] as List<dynamic>?) ?? [];
    }
    throw Exception(response.data['error'] ?? 'Failed to fetch product images');
  }

  Future<void> deleteProductImage(String imageId) async {
    final response = await _apiClient.dio.delete('/products/images/$imageId');
    if (response.statusCode != 200 || response.data['status'] != 'success') {
      throw Exception(response.data['error'] ?? 'Failed to delete product image');
    }
  }

  Future<void> reorderProductImages(String productId, List<String> imageIds) async {
    final response = await _apiClient.dio.put(
      '/products/$productId/images/reorder',
      data: {'image_ids': imageIds},
    );
    if (response.statusCode != 200 || response.data['status'] != 'success') {
      throw Exception(response.data['error'] ?? 'Failed to reorder product images');
    }
  }

  Future<void> setPrimaryProductImage(String productId, String imageId) async {
    final response = await _apiClient.dio.put('/products/$productId/images/$imageId/primary');
    if (response.statusCode != 200 || response.data['status'] != 'success') {
      throw Exception(response.data['error'] ?? 'Failed to set primary image');
    }
  }

  // ==================== Purchases ====================

  Future<List<dynamic>> getPurchases() async {
    final response = await _apiClient.dio.get('/vendor/purchases');
    if (response.statusCode == 200 && response.data['status'] == 'success') {
      return (response.data['data'] as List<dynamic>?) ?? [];
    }
    throw Exception(response.data['error'] ?? 'Failed to fetch purchases');
  }

  Future<Map<String, dynamic>> createPurchase(Map<String, dynamic> data) async {
    final response = await _apiClient.dio.post('/vendor/purchases', data: data);
    if ((response.statusCode == 200 || response.statusCode == 201) &&
        (response.data['status'] == 'success' || response.data['status'] == 'created')) {
      return response.data['data'] as Map<String, dynamic>;
    }
    throw Exception(response.data['error'] ?? 'Failed to create purchase');
  }

  // ==================== Product Variants ====================

  Future<List<dynamic>> listProductVariants(String productId) async {
    final response = await _apiClient.dio.get('/products/$productId/variants');
    if (response.statusCode == 200 && response.data['status'] == 'success') {
      return (response.data['data'] as List<dynamic>?) ?? [];
    }
    throw Exception(response.data['error'] ?? 'Failed to fetch variants');
  }

  Future<Map<String, dynamic>> createVariant(String productId, Map<String, dynamic> data) async {
    final response = await _apiClient.dio.post('/products/$productId/variants', data: data);
    if ((response.statusCode == 200 || response.statusCode == 201) &&
        (response.data['status'] == 'success' || response.data['status'] == 'created')) {
      return response.data['data'] as Map<String, dynamic>;
    }
    throw Exception(response.data['error'] ?? 'Failed to create variant');
  }

  Future<Map<String, dynamic>> updateVariant(String productId, String variantId, Map<String, dynamic> data) async {
    final response = await _apiClient.dio.put('/products/$productId/variants/$variantId', data: data);
    if (response.statusCode == 200 && response.data['status'] == 'success') {
      return response.data['data'] as Map<String, dynamic>;
    }
    throw Exception(response.data['error'] ?? 'Failed to update variant');
  }

  Future<void> deleteVariant(String productId, String variantId) async {
    final response = await _apiClient.dio.delete('/products/$productId/variants/$variantId');
    if (response.statusCode != 200 || response.data['status'] != 'success') {
      throw Exception(response.data['error'] ?? 'Failed to delete variant');
    }
  }
}
