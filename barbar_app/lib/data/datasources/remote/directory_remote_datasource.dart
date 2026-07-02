import '../../../core/network/api_client.dart';
import '../../models/barber_model.dart';

class DirectoryRemoteDataSource {
  final ApiClient _apiClient;

  DirectoryRemoteDataSource(this._apiClient);

  Future<List<BarberModel>> getNearbyBarbers({
    required double latitude,
    required double longitude,
    int radius = 5000,
    String? search,
  }) async {
    final response = await _apiClient.dio.get(
      '/public/barbers',
      queryParameters: {
        'latitude': latitude,
        'longitude': longitude,
        'radius': radius,
        if (search != null) 'search': search,
      },
    );
    if (response.statusCode == 200 && (response.data['status'] == 'success' || response.data['status'] == 'created')) {
      final List<dynamic> data = response.data['data'];
      return data.map((e) => BarberModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception(response.data['error'] ?? 'Failed to fetch barbers');
  }
}
