import '../../data/models/vendor_model.dart';
import '../../data/models/vendor_warehouse_model.dart';
import '../../data/models/vendor_brand_model.dart';
import '../../data/models/product_model.dart';
import '../../data/models/product_variant_model.dart';
import '../../data/models/order_model.dart';
import '../../data/models/vendor_purchase_model.dart';

abstract class VendorRepository {
  // Profile
  Future<VendorModel> register(Map<String, dynamic> data);
  Future<VendorModel> getProfile();
  Future<VendorModel> updateProfile(Map<String, dynamic> data);
  Future<Map<String, dynamic>> getDashboard();

  // Warehouses
  Future<WarehouseModel> createWarehouse(Map<String, dynamic> data);
  Future<List<WarehouseModel>> listWarehouses();
  Future<WarehouseModel> getWarehouse(String warehouseId);
  Future<WarehouseModel> updateWarehouse(String warehouseId, Map<String, dynamic> data);
  Future<void> deleteWarehouse(String warehouseId);
  Future<void> setDefaultWarehouse(String warehouseId);

  // Brands
  Future<List<VendorBrandModel>> getBrands();
  Future<VendorBrandModel> createBrand(Map<String, dynamic> data);
  Future<VendorBrandModel> updateBrand(String id, Map<String, dynamic> data);
  Future<void> deleteBrand(String id);

  // Products
  Future<List<ProductModel>> listProducts();
  Future<ProductModel> createProduct(Map<String, dynamic> data);
  Future<ProductModel> updateProduct(String productId, Map<String, dynamic> data);
  Future<void> deleteProduct(String productId);

  // Orders
  Future<List<OrderModel>> listOrders({String? status});
  Future<void> updateOrderStatus(String orderId, String status);
  Future<OrderModel> getOrderById(String orderId);
  Future<OrderModel> acceptOrder(String orderId);
  Future<OrderModel> rejectOrder(String orderId, {String? reason});
  Future<OrderModel> packOrder(String orderId);
  Future<OrderModel> readyForPickup(String orderId);

  // Purchases
  Future<List<VendorPurchaseModel>> getPurchases();
  Future<VendorPurchaseModel> createPurchase(Map<String, dynamic> data);

  // Product Variants
  Future<List<ProductVariantModel>> listProductVariants(String productId);
  Future<ProductVariantModel> createVariant(String productId, Map<String, dynamic> data);
  Future<ProductVariantModel> updateVariant(String productId, String variantId, Map<String, dynamic> data);
  Future<void> deleteVariant(String productId, String variantId);
}
