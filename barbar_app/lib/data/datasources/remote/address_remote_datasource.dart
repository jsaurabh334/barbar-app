import '../../../core/network/api_client.dart';

class AddressRemoteDataSource {
  final ApiClient _apiClient;

  AddressRemoteDataSource(this._apiClient);

  Future<List<Map<String, dynamic>>> getAddresses() async {
    final response = await _apiClient.dio.get('/addresses');
    if (response.statusCode == 200 && (response.data['status'] == 'success' || response.data['status'] == 'created')) {
      final data = (response.data['data'] as List<dynamic>?) ?? [];
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception(response.data['error'] ?? 'Failed to fetch addresses');
  }

  Future<Map<String, dynamic>> createAddress(Map<String, dynamic> address) async {
    final response = await _apiClient.dio.post('/addresses', data: address);
    if (response.statusCode == 201 && (response.data['status'] == 'success' || response.data['status'] == 'created')) {
      return response.data['data'] as Map<String, dynamic>;
    }
    throw Exception(response.data['error'] ?? 'Failed to create address');
  }

  Future<Map<String, dynamic>> updateAddress(String id, Map<String, dynamic> address) async {
    final response = await _apiClient.dio.put('/addresses/$id', data: address);
    if (response.statusCode == 200 && (response.data['status'] == 'success' || response.data['status'] == 'created')) {
      return response.data['data'] as Map<String, dynamic>;
    }
    throw Exception(response.data['error'] ?? 'Failed to update address');
  }

  Future<void> deleteAddress(String id) async {
    final response = await _apiClient.dio.delete('/addresses/$id');
    if (response.statusCode != 200 || (response.data['status'] != 'success' && response.data['status'] != 'created')) {
      throw Exception(response.data['error'] ?? 'Failed to delete address');
    }
  }

  Future<void> setDefaultAddress(String id) async {
    final response = await _apiClient.dio.put('/addresses/$id/default');
    if (response.statusCode != 200 || (response.data['status'] != 'success' && response.data['status'] != 'created')) {
      throw Exception(response.data['error'] ?? 'Failed to set default address');
    }
  }
}
