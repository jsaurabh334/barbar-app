import '../../../core/network/api_client.dart';
import '../../models/barber_model.dart';
import '../../models/category_model.dart';

class DirectoryRemoteDataSource {
  final ApiClient _apiClient;

  DirectoryRemoteDataSource(this._apiClient);

  Future<List<BarberModel>> getNearbyBarbers({
    required double latitude,
    required double longitude,
    int radius = 5000,
    String? search,
    double? minRating,
    bool? openNow,
    String? categoryId,
  }) async {
    final response = await _apiClient.dio.get(
      '/public/barbers',
      queryParameters: {
        'latitude': latitude,
        'longitude': longitude,
        'radius': radius,
        if (search != null) 'search': search,
        if (minRating != null) 'min_rating': minRating,
        if (openNow == true) 'open_now': true,
        if (categoryId != null) 'category_id': categoryId,
      },
    );
    if (response.statusCode == 200 && (response.data['status'] == 'success' || response.data['status'] == 'created')) {
      final List<dynamic> data = response.data['data'];
      return data.map((e) => BarberModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception(response.data['error'] ?? 'Failed to fetch barbers');
  }

  Future<List<CategoryModel>> getCategories() async {
    final response = await _apiClient.dio.get('/public/categories', queryParameters: {'type': 'barber_service'});
    if (response.statusCode == 200 && response.data['status'] == 'success') {
      final List<dynamic> data = response.data['data'];
      return data.map((e) => CategoryModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception(response.data['error'] ?? 'Failed to fetch categories');
  }
}
