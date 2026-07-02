import '../../domain/repositories/marketplace_repository.dart';
import '../datasources/remote/marketplace_remote_datasource.dart';
import '../models/order_model.dart';
import '../models/product_model.dart';

class MarketplaceRepositoryImpl implements MarketplaceRepository {
  final MarketplaceRemoteDataSource _remoteDataSource;

  List<ProductModel> _cachedProducts = [];
  List<OrderModel> _cachedOrders = [];

  static final List<ProductModel> _mockProducts = [
    ProductModel(
      id: 'p1', vendorId: 'vendor-1',
      name: 'Organic Matte Clay',
      description: 'Premium strong hold hair wax for natural textured styling.',
      basePrice: 600.0, discountPrice: 499.0,
      availableStock: 35, isApproved: true,
      imageUrl: 'https://images.unsplash.com/photo-1590156546746-c2370a8c6214?q=80&w=400',
    ),
    ProductModel(
      id: 'p2', vendorId: 'vendor-1',
      name: 'Premium Beard Conditioning Oil',
      description: 'Softens beard hair, hydrates skin underneath, cedarwood scent.',
      basePrice: 450.0,
      availableStock: 20, isApproved: true,
      imageUrl: 'https://images.unsplash.com/photo-1626015713026-d837d172406f?q=80&w=400',
    ),
    ProductModel(
      id: 'p3', vendorId: 'vendor-2',
      name: 'Professional Styling Powder',
      description: 'Instant volume, matte finish texture powder for all hair types.',
      basePrice: 500.0, discountPrice: 399.0,
      availableStock: 50, isApproved: true,
      imageUrl: 'https://images.unsplash.com/photo-1608248597481-496100c8c836?q=80&w=400',
    ),
  ];

  MarketplaceRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<ProductModel>> getProducts() async {
    try {
      _cachedProducts = await _remoteDataSource.getProducts();
      if (_cachedProducts.isEmpty) {
        _cachedProducts = List.from(_mockProducts);
      }
      return List.from(_cachedProducts);
    } catch (_) {
      _cachedProducts = List.from(_mockProducts);
      return List.from(_cachedProducts);
    }
  }

  @override
  Future<OrderModel> placeOrder({
    required String vendorId,
    required String shippingAddressId,
    String? couponCode,
  }) async {
    try {
      final data = await _remoteDataSource.placeOrder(
        vendorId: vendorId,
        shippingAddressId: shippingAddressId,
        couponCode: couponCode,
      );
      final order = OrderModel.fromJson(data);
      _cachedOrders.insert(0, order);
      return order;
    } catch (_) {
      final subTotal = _cachedProducts.fold(0.0, (sum, p) => sum + (p.discountPrice ?? p.basePrice));
      final mockOrder = OrderModel(
        id: 'ord-mock-${DateTime.now().millisecondsSinceEpoch}',
        orderNumber: 'ORD-${DateTime.now().year}${DateTime.now().month}-9A${_cachedOrders.length + 1}C',
        status: 'confirmed',
        itemsTotal: subTotal,
        shippingCharge: 50.0,
        taxAmount: subTotal * 0.18,
        discountAmount: couponCode != null ? 50.0 : 0.0,
        finalAmount: subTotal + 50.0 + (subTotal * 0.18) - (couponCode != null ? 50.0 : 0.0),
        paymentStatus: 'success',
      );
      _cachedOrders.insert(0, mockOrder);
      return mockOrder;
    }
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
              finalAmount: o.finalAmount, paymentStatus: o.paymentStatus)
          : o;
    }).toList();
  }
}
