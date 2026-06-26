import '../../data/models/product_model.dart';
import '../../data/models/order_model.dart';

abstract class MarketplaceRepository {
  Future<List<ProductModel>> getProducts();
  Future<OrderModel> placeOrder({
    required String vendorId,
    required String shippingAddressId,
    String? couponCode,
  });
  Future<List<OrderModel>> getOrders();
  Future<void> updateOrderStatus(String orderId, String status);
}
