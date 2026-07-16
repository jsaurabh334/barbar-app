import '../../data/models/vendor_model.dart';
import '../../data/models/vendor_branch_model.dart';
import '../../data/models/vendor_image_model.dart';
import '../../data/models/vendor_working_hour_model.dart';
import '../../data/models/vendor_holiday_model.dart';
import '../../data/models/product_model.dart';
import '../../data/models/order_model.dart';

abstract class VendorRepository {
  // Profile
  Future<VendorModel> register(Map<String, dynamic> data);
  Future<VendorModel> getProfile();
  Future<VendorModel> updateProfile(Map<String, dynamic> data);
  Future<Map<String, dynamic>> getDashboard();

  // Branches
  Future<VendorBranchModel> createBranch(Map<String, dynamic> data);
  Future<List<VendorBranchModel>> listBranches();
  Future<VendorBranchModel> getBranch(String branchId);
  Future<VendorBranchModel> updateBranch(String branchId, Map<String, dynamic> data);
  Future<void> deleteBranch(String branchId);
  Future<void> setDefaultBranch(String branchId);

  // Gallery
  Future<VendorImageModel> uploadImage(Map<String, dynamic> data);
  Future<List<VendorImageModel>> listImages({String? branchId, String? imageType});
  Future<void> deleteImage(String imageId);
  Future<void> reorderImages(List<String> imageIds);

  // Working Hours
  Future<List<VendorWorkingHourModel>> setWorkingHours(String branchId, List<Map<String, dynamic>> hours);
  Future<List<VendorWorkingHourModel>> getWorkingHours(String branchId);

  // Holidays
  Future<VendorHolidayModel> addHoliday(String branchId, Map<String, dynamic> data);
  Future<List<VendorHolidayModel>> listHolidays(String branchId);
  Future<void> deleteHoliday(String branchId, String holidayId);

  // Products
  Future<List<ProductModel>> listProducts();
  Future<ProductModel> createProduct(Map<String, dynamic> data);
  Future<ProductModel> updateProduct(String productId, Map<String, dynamic> data);
  Future<void> deleteProduct(String productId);

  // Orders
  Future<List<OrderModel>> listOrders({String? status});
  Future<void> updateOrderStatus(String orderId, String status);
}
