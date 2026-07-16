import '../../domain/repositories/vendor_repository.dart';
import '../datasources/remote/vendor_remote_datasource.dart';
import '../models/vendor_model.dart';
import '../models/vendor_branch_model.dart';
import '../models/vendor_image_model.dart';
import '../models/vendor_working_hour_model.dart';
import '../models/vendor_holiday_model.dart';
import '../models/product_model.dart';
import '../models/order_model.dart';

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
  Future<VendorBranchModel> createBranch(Map<String, dynamic> data) async {
    final json = await _remoteDataSource.createBranch(data);
    return VendorBranchModel.fromJson(json);
  }

  @override
  Future<List<VendorBranchModel>> listBranches() async {
    final list = await _remoteDataSource.listBranches();
    return list.map((e) => VendorBranchModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<VendorBranchModel> getBranch(String branchId) async {
    final json = await _remoteDataSource.getBranch(branchId);
    return VendorBranchModel.fromJson(json);
  }

  @override
  Future<VendorBranchModel> updateBranch(String branchId, Map<String, dynamic> data) async {
    final json = await _remoteDataSource.updateBranch(branchId, data);
    return VendorBranchModel.fromJson(json);
  }

  @override
  Future<void> deleteBranch(String branchId) async {
    await _remoteDataSource.deleteBranch(branchId);
  }

  @override
  Future<void> setDefaultBranch(String branchId) async {
    await _remoteDataSource.setDefaultBranch(branchId);
  }

  @override
  Future<VendorImageModel> uploadImage(Map<String, dynamic> data) async {
    final json = await _remoteDataSource.uploadImage(data);
    return VendorImageModel.fromJson(json);
  }

  @override
  Future<List<VendorImageModel>> listImages({String? branchId, String? imageType}) async {
    final list = await _remoteDataSource.listImages(branchId: branchId, imageType: imageType);
    return list.map((e) => VendorImageModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> deleteImage(String imageId) async {
    await _remoteDataSource.deleteImage(imageId);
  }

  @override
  Future<void> reorderImages(List<String> imageIds) async {
    await _remoteDataSource.reorderImages(imageIds);
  }

  @override
  Future<List<VendorWorkingHourModel>> setWorkingHours(String branchId, List<Map<String, dynamic>> hours) async {
    final list = await _remoteDataSource.setWorkingHours(branchId, hours);
    return list.map((e) => VendorWorkingHourModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<VendorWorkingHourModel>> getWorkingHours(String branchId) async {
    final list = await _remoteDataSource.getWorkingHours(branchId);
    return list.map((e) => VendorWorkingHourModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<VendorHolidayModel> addHoliday(String branchId, Map<String, dynamic> data) async {
    final json = await _remoteDataSource.addHoliday(branchId, data);
    return VendorHolidayModel.fromJson(json);
  }

  @override
  Future<List<VendorHolidayModel>> listHolidays(String branchId) async {
    final list = await _remoteDataSource.listHolidays(branchId);
    return list.map((e) => VendorHolidayModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> deleteHoliday(String branchId, String holidayId) async {
    await _remoteDataSource.deleteHoliday(branchId, holidayId);
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
}
