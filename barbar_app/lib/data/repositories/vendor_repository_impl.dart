import '../../domain/repositories/vendor_repository.dart';
import '../datasources/remote/vendor_remote_datasource.dart';
import '../models/vendor_model.dart';
import '../models/vendor_warehouse_model.dart';
import '../models/vendor_brand_model.dart';
import '../models/product_model.dart';
import '../models/product_variant_model.dart';
import '../models/order_model.dart';
import '../models/vendor_purchase_model.dart';

class VendorRepositoryImpl implements VendorRepository {
  final VendorRemoteDataSource _remoteDataSource;

  VendorRepositoryImpl(this._remoteDataSource);

  @override
  Future<VendorModel> register(Map<String, dynamic> data) async {
    final json = await _remoteDataSource.register(data);
    return VendorModel.fromJson(json);
  }

  @override
  Future<VendorModel> getProfile() async {
    final json = await _remoteDataSource.getProfile();
    return VendorModel.fromJson(json);
  }

  @override
  Future<VendorModel> updateProfile(Map<String, dynamic> data) async {
    final json = await _remoteDataSource.updateProfile(data);
    return VendorModel.fromJson(json);
  }

  @override
  Future<Map<String, dynamic>> getDashboard() async {
    return await _remoteDataSource.getDashboard();
  }

  @override
  Future<WarehouseModel> createWarehouse(Map<String, dynamic> data) async {
    final json = await _remoteDataSource.createWarehouse(data);
    return WarehouseModel.fromJson(json);
  }

  @override
  Future<List<WarehouseModel>> listWarehouses() async {
    final list = await _remoteDataSource.listWarehouses();
    return list.map((e) => WarehouseModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<WarehouseModel> getWarehouse(String warehouseId) async {
    final json = await _remoteDataSource.getWarehouse(warehouseId);
    return WarehouseModel.fromJson(json);
  }

  @override
  Future<WarehouseModel> updateWarehouse(String warehouseId, Map<String, dynamic> data) async {
    final json = await _remoteDataSource.updateWarehouse(warehouseId, data);
    return WarehouseModel.fromJson(json);
  }

  @override
  Future<void> deleteWarehouse(String warehouseId) async {
    await _remoteDataSource.deleteWarehouse(warehouseId);
  }

  @override
  Future<void> setDefaultWarehouse(String warehouseId) async {
    await _remoteDataSource.setDefaultWarehouse(warehouseId);
  }

  // Brands

  @override
  Future<List<VendorBrandModel>> getBrands() async {
    final list = await _remoteDataSource.getBrands();
    return list.map((e) => VendorBrandModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<VendorBrandModel> createBrand(Map<String, dynamic> data) async {
    final json = await _remoteDataSource.createBrand(data);
    return VendorBrandModel.fromJson(json);
  }

  @override
  Future<VendorBrandModel> updateBrand(String id, Map<String, dynamic> data) async {
    final json = await _remoteDataSource.updateBrand(id, data);
    return VendorBrandModel.fromJson(json);
  }

  @override
  Future<void> deleteBrand(String id) async {
    await _remoteDataSource.deleteBrand(id);
  }

  @override
  Future<List<ProductModel>> listProducts() async {
    final list = await _remoteDataSource.listProducts();
    return list.map((e) => ProductModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<ProductModel> createProduct(Map<String, dynamic> data) async {
    final json = await _remoteDataSource.createProduct(data);
    return ProductModel.fromJson(json);
  }

  @override
  Future<ProductModel> updateProduct(String productId, Map<String, dynamic> data) async {
    final json = await _remoteDataSource.updateProduct(productId, data);
    return ProductModel.fromJson(json);
  }

  @override
  Future<void> deleteProduct(String productId) async {
    await _remoteDataSource.deleteProduct(productId);
  }

  @override
  Future<List<OrderModel>> listOrders({String? status}) async {
    final list = await _remoteDataSource.listOrders(status: status);
    return list.map((e) => OrderModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> updateOrderStatus(String orderId, String status) async {
    await _remoteDataSource.updateOrderStatus(orderId, status);
  }

  @override
  Future<OrderModel> getOrderById(String orderId) async {
    final json = await _remoteDataSource.getOrderById(orderId);
    return OrderModel.fromJson(json);
  }

  @override
  Future<OrderModel> acceptOrder(String orderId) async {
    final json = await _remoteDataSource.acceptOrder(orderId);
    return OrderModel.fromJson(json);
  }

  @override
  Future<OrderModel> rejectOrder(String orderId, {String? reason}) async {
    final json = await _remoteDataSource.rejectOrder(orderId, reason: reason);
    return OrderModel.fromJson(json);
  }

  @override
  Future<OrderModel> packOrder(String orderId) async {
    final json = await _remoteDataSource.packOrder(orderId);
    return OrderModel.fromJson(json);
  }

  @override
  Future<OrderModel> readyForPickup(String orderId) async {
    final json = await _remoteDataSource.readyForPickup(orderId);
    return OrderModel.fromJson(json);
  }

  @override
  Future<Map<String, dynamic>> getOrderDeliveryInfo(String orderId) async {
    return await _remoteDataSource.getOrderDeliveryInfo(orderId);
  }

  // Purchases

  @override
  Future<List<VendorPurchaseModel>> getPurchases() async {
    final list = await _remoteDataSource.getPurchases();
    return list.map((e) => VendorPurchaseModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<VendorPurchaseModel> createPurchase(Map<String, dynamic> data) async {
    final json = await _remoteDataSource.createPurchase(data);
    return VendorPurchaseModel.fromJson(json);
  }

  // Product Variants

  @override
  Future<List<ProductVariantModel>> listProductVariants(String productId) async {
    final list = await _remoteDataSource.listProductVariants(productId);
    return list.map((e) => ProductVariantModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<ProductVariantModel> createVariant(String productId, Map<String, dynamic> data) async {
    final json = await _remoteDataSource.createVariant(productId, data);
    return ProductVariantModel.fromJson(json);
  }

  @override
  Future<ProductVariantModel> updateVariant(String productId, String variantId, Map<String, dynamic> data) async {
    final json = await _remoteDataSource.updateVariant(productId, variantId, data);
    return ProductVariantModel.fromJson(json);
  }

  @override
  Future<void> deleteVariant(String productId, String variantId) async {
    await _remoteDataSource.deleteVariant(productId, variantId);
  }
}
