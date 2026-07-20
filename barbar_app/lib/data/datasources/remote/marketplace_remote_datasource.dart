import '../../../core/network/api_client.dart';
import '../../models/order_model.dart';
import '../../models/product_model.dart';

class MarketplaceRemoteDataSource {
  final ApiClient _apiClient;

  MarketplaceRemoteDataSource(this._apiClient);

  Future<List<ProductModel>> getProducts() async {
    final response = await _apiClient.dio.get('/public/products');
    if (response.statusCode == 200 && (response.data['status'] == 'success' || response.data['status'] == 'created')) {
      final data = (response.data['data'] as List<dynamic>?) ?? [];
      return data.map((e) => ProductModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception(response.data['error'] ?? 'Failed to fetch products');
  }

  Future<Map<String, dynamic>> placeOrder({
    required String vendorId,
    required String shippingAddressId,
    String? couponCode,
    required List<Map<String, dynamic>> items,
    required String paymentMethod,
  }) async {
    final response = await _apiClient.dio.post(
      '/orders',
      data: {
        'vendor_id': vendorId,
        'shipping_address_id': shippingAddressId,
        'items': items,
        'payment_method': paymentMethod,
        if (couponCode != null) 'coupon_code': couponCode,
      },
    );
    if ((response.statusCode == 200 || response.statusCode == 201) && (response.data['status'] == 'success' || response.data['status'] == 'created')) {
      return response.data['data'] as Map<String, dynamic>;
    }
    throw Exception(response.data['error'] ?? 'Order placement failed');
  }

  Future<List<OrderModel>> getOrders() async {
    final response = await _apiClient.dio.get('/orders');
    if (response.statusCode == 200 && (response.data['status'] == 'success' || response.data['status'] == 'created')) {
      final data = (response.data['data'] as List<dynamic>?) ?? [];
      return data.map((e) => OrderModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception(response.data['error'] ?? 'Failed to fetch orders');
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    final response = await _apiClient.dio.put(
      '/orders/$orderId/status',
      data: {'status': status},
    );
    if (response.statusCode != 200 || (response.data['status'] != 'success' && response.data['status'] != 'created')) {
      throw Exception(response.data['error'] ?? 'Failed to update order status');
    }
  }

  Future<Map<String, dynamic>> getDriverLocation(String orderId) async {
    final response = await _apiClient.dio.get('/public/orders/$orderId/driver-location');
    if (response.statusCode == 200 && response.data['status'] == 'success') {
      return response.data['data'] as Map<String, dynamic>;
    }
    throw Exception(response.data['error'] ?? 'Failed to fetch driver location');
  }
}
