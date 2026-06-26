import '../../../core/network/api_client.dart';
import '../../models/order_model.dart';
import '../../models/product_model.dart';

class MarketplaceRemoteDataSource {
  final ApiClient _apiClient;

  MarketplaceRemoteDataSource(this._apiClient);

  Future<List<ProductModel>> getProducts() async {
    final response = await _apiClient.dio.get('/public/products');
    if (response.statusCode == 200 && response.data['success'] == true) {
      final List<dynamic> data = response.data['data'];
      return data.map((e) => ProductModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception(response.data['error'] ?? 'Failed to fetch products');
  }

  Future<Map<String, dynamic>> placeOrder({
    required String vendorId,
    required String shippingAddressId,
    String? couponCode,
  }) async {
    final response = await _apiClient.dio.post(
      '/orders',
      data: {
        'vendor_id': vendorId,
        'shipping_address_id': shippingAddressId,
        if (couponCode != null) 'coupon_code': couponCode,
      },
    );
    if ((response.statusCode == 200 || response.statusCode == 201) && response.data['success'] == true) {
      return response.data['data'] as Map<String, dynamic>;
    }
    throw Exception(response.data['error'] ?? 'Order placement failed');
  }

  Future<List<OrderModel>> getOrders() async {
    final response = await _apiClient.dio.get('/orders');
    if (response.statusCode == 200 && response.data['success'] == true) {
      final List<dynamic> data = response.data['data'];
      return data.map((e) => OrderModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception(response.data['error'] ?? 'Failed to fetch orders');
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    final response = await _apiClient.dio.put(
      '/orders/$orderId/status',
      data: {'status': status},
    );
    if (response.statusCode != 200 || response.data['success'] != true) {
      throw Exception(response.data['error'] ?? 'Failed to update order status');
    }
  }
}
