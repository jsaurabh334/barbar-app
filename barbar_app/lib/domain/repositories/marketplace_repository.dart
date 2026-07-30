import '../../data/models/product_model.dart';
import '../../data/models/order_model.dart';

abstract class MarketplaceRepository {
  Future<List<ProductModel>> getProducts();
  Future<OrderModel> placeOrder({
    required String vendorId,
    required String shippingAddressId,
    String? couponCode,
    required List<Map<String, dynamic>> items,
    required String paymentMethod,
  });
  Future<List<OrderModel>> getOrders();
  Future<void> updateOrderStatus(String orderId, String status);
  Future<Map<String, dynamic>> getDriverLocation(String orderId);
  Future<void> cancelOrder(String orderId, {String? reason});
  Future<void> submitReturnRequest(String orderId, {required String reason, List<String>? images});
  Future<void> reportIssue(String orderId, {required String issueType, required String description});
  Future<Map<String, dynamic>> initiatePayment(String orderId, {required String gateway});
  Future<Map<String, dynamic>> verifyPayment({
    required String paymentId,
    required String gateway,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  });
}
