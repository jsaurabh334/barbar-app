import '../../data/models/barber_model.dart';
import '../../data/models/category_model.dart';
import '../../data/models/vendor_model.dart';

abstract class DirectoryRepository {
  Future<List<BarberModel>> getNearbyBarbers({
    required double latitude,
    required double longitude,
    int radius = 5000,
    String? search,
    double? minRating,
    bool? openNow,
    String? categoryId,
  });

  Future<List<CategoryModel>> getCategories();

  Future<List<Map<String, dynamic>>> getBarberStaff(String barberId);

  Future<VendorModel> getVendorDetail(String vendorId);

  Future<List<CategoryModel>> getProductCategories();
}
