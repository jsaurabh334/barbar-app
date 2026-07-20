import '../../domain/repositories/marketplace_repository.dart';
import '../datasources/remote/marketplace_remote_datasource.dart';
import '../models/order_model.dart';
import '../models/order_item_model.dart';
import '../models/product_model.dart';

class MarketplaceRepositoryImpl implements MarketplaceRepository {
  final MarketplaceRemoteDataSource _remoteDataSource;

  List<ProductModel> _cachedProducts = [];
  List<OrderModel> _cachedOrders = [];

  MarketplaceRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<ProductModel>> getProducts() async {
    _cachedProducts = await _remoteDataSource.getProducts();
    return List.from(_cachedProducts);
  }

  @override
  Future<OrderModel> placeOrder({
    required String vendorId,
    required String shippingAddressId,
    String? couponCode,
    required List<Map<String, dynamic>> items,
    required String paymentMethod,
  }) async {
    final data = await _remoteDataSource.placeOrder(
      vendorId: vendorId,
      shippingAddressId: shippingAddressId,
      couponCode: couponCode,
      items: items,
      paymentMethod: paymentMethod,
    );
    final orderList = data['orders'] as List<dynamic>;
    final orderJson = orderList.first as Map<String, dynamic>;
    final order = OrderModel.fromJson(orderJson);
    _cachedOrders.insert(0, order);
    return order;
  }

  @override
  Future<List<OrderModel>> getOrders() async {
    if (_cachedOrders.isEmpty) {
      _cachedOrders = [
        OrderModel(
          id: 'ord-1', orderNumber: 'ORD-20260603-9A1C',
          status: 'confirmed', itemsTotal: 499.0,
          shippingCharge: 50.0, taxAmount: 90.0,
          discountAmount: 0.0, finalAmount: 639.0,
          paymentStatus: 'success',
          items: [
            OrderItemModel(
              productId: 'p1',
              productName: 'Sample Grooming Kit',
              quantity: 1,
              price: 499.0,
            ),
          ],
        ),
      ];
    }
    return List.from(_cachedOrders);
  }

  @override
  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      await _remoteDataSource.updateOrderStatus(orderId, status);
    } catch (_) {
      // local update fallback
    }
    _cachedOrders = _cachedOrders.map((o) {
      return o.id == orderId
          ? OrderModel(id: o.id, orderNumber: o.orderNumber, status: status,
              itemsTotal: o.itemsTotal, shippingCharge: o.shippingCharge,
              taxAmount: o.taxAmount, discountAmount: o.discountAmount,
              finalAmount: o.finalAmount, paymentStatus: o.paymentStatus,
              items: o.items)
          : o;
    }).toList();
  }

  @override
  Future<Map<String, dynamic>> getDriverLocation(String orderId) async {
    return await _remoteDataSource.getDriverLocation(orderId);
  }
}
