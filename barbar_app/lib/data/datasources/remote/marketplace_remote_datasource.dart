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

  Future<void> cancelOrder(String orderId, {String? reason}) async {
    final response = await _apiClient.dio.put(
      '/orders/$orderId/cancel',
      data: {'reason': reason ?? ''},
    );
    if (response.statusCode != 200 || (response.data['status'] != 'success' && response.data['status'] != 'created')) {
      throw Exception(response.data['error'] ?? 'Failed to cancel order');
    }
  }

  Future<void> submitReturnRequest(String orderId, {required String reason, List<String>? images}) async {
    final response = await _apiClient.dio.post(
      '/orders/$orderId/return',
      data: {
        'reason': reason,
      },
    );
    if ((response.statusCode != 200 && response.statusCode != 201) || (response.data['status'] != 'success' && response.data['status'] != 'created')) {
      throw Exception(response.data['error'] ?? 'Failed to submit return request');
    }
  }

  Future<void> reportIssue(String orderId, {required String issueType, required String description}) async {
    final response = await _apiClient.dio.post(
      '/orders/$orderId/report',
      data: {
        'issue_type': issueType,
        'description': description,
      },
    );
    if (response.statusCode != 200 || response.data['status'] != 'success') {
      throw Exception(response.data['error'] ?? 'Failed to report issue');
    }
  }

  Future<Map<String, dynamic>> initiatePayment({
    required String orderId,
    required String gateway,
  }) async {
    final response = await _apiClient.dio.post(
      '/payments/initiate',
      data: {
        'order_id': orderId,
        'gateway': gateway,
      },
    );
    if (response.statusCode == 200 && response.data['status'] == 'success') {
      return response.data['data'] as Map<String, dynamic>;
    }
    throw Exception(response.data['error'] ?? 'Payment initiation failed');
  }

  Future<Map<String, dynamic>> verifyPayment({
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
    if (response.statusCode == 200 && response.data['status'] == 'success') {
      return response.data['data'] as Map<String, dynamic>;
    }
    throw Exception(response.data['error'] ?? 'Payment verification failed');
  }
}
