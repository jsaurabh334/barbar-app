import '../../domain/repositories/directory_repository.dart';
import '../datasources/remote/directory_remote_datasource.dart';
import '../models/barber_model.dart';
import '../models/category_model.dart';

class DirectoryRepositoryImpl implements DirectoryRepository {
  final DirectoryRemoteDataSource _remoteDataSource;

  DirectoryRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<BarberModel>> getNearbyBarbers({
    required double latitude,
    required double longitude,
    int radius = 5000,
    String? search,
    double? minRating,
    bool? openNow,
    String? categoryId,
  }) async {
    final barbers = await _remoteDataSource.getNearbyBarbers(
      latitude: latitude,
      longitude: longitude,
      radius: radius,
      search: search,
      minRating: minRating,
      openNow: openNow,
      categoryId: categoryId,
    );
    return barbers;
  }

  @override
  Future<List<CategoryModel>> getCategories() async {
    return _remoteDataSource.getCategories();
  }
}
