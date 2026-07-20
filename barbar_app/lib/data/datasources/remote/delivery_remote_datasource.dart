import '../../../core/network/api_client.dart';

class DeliveryRemoteDataSource {
  final ApiClient _apiClient;

  DeliveryRemoteDataSource(this._apiClient);

  // ==================== Profile ====================

  Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    final response = await _apiClient.dio.post('/delivery-partners/register', data: data);
    if ((response.statusCode == 200 || response.statusCode == 201) &&
        (response.data['status'] == 'success' || response.data['status'] == 'created')) {
      return response.data['data'] as Map<String, dynamic>;
    }
    throw Exception(response.data['error'] ?? 'Registration failed');
  }

  Future<Map<String, dynamic>> getProfile() async {
    final response = await _apiClient.dio.get('/delivery-partners/profile');
    if (response.statusCode == 200 && response.data['status'] == 'success') {
      return response.data['data'] as Map<String, dynamic>;
    }
    throw Exception(response.data['error'] ?? 'Failed to fetch profile');
  }

  Future<List<dynamic>> getAssignedOrders() async {
    final response = await _apiClient.dio.get('/delivery/orders');
    if (response.statusCode == 200 && response.data['status'] == 'success') {
      return (response.data['data'] as List<dynamic>?) ?? [];
    }
    throw Exception(response.data['error'] ?? 'Failed to fetch assigned orders');
  }

  Future<Map<String, dynamic>> getOrderById(String orderId) async {
    final response = await _apiClient.dio.get('/delivery/orders/$orderId');
    if (response.statusCode == 200 && response.data['status'] == 'success') {
      return response.data['data'] as Map<String, dynamic>;
    }
    throw Exception(response.data['error'] ?? 'Failed to fetch order');
  }

  Future<Map<String, dynamic>> pickupOrder(String orderId) async {
    final response = await _apiClient.dio.put('/delivery/orders/$orderId/pickup');
    if (response.statusCode == 200 && response.data['status'] == 'success') {
      return response.data['data'] as Map<String, dynamic>;
    }
    throw Exception(response.data['error'] ?? 'Failed to pickup order');
  }

  Future<Map<String, dynamic>> outForDelivery(String orderId) async {
    final response = await _apiClient.dio.put('/delivery/orders/$orderId/out-for-delivery');
    if (response.statusCode == 200 && response.data['status'] == 'success') {
      return response.data['data'] as Map<String, dynamic>;
    }
    throw Exception(response.data['error'] ?? 'Failed to mark order out for delivery');
  }

  Future<void> acceptAssignment(String orderId) async {
    final response = await _apiClient.dio.put('/delivery/orders/$orderId/accept');
    if (response.statusCode == 200 && response.data['status'] == 'success') {
      return;
    }
    throw Exception(response.data['error'] ?? 'Failed to accept assignment');
  }

  Future<void> rejectAssignment(String orderId) async {
    final response = await _apiClient.dio.put('/delivery/orders/$orderId/reject');
    if (response.statusCode == 200 && response.data['status'] == 'success') {
      return;
    }
    throw Exception(response.data['error'] ?? 'Failed to reject assignment');
  }

  Future<Map<String, dynamic>> deliverOrder(String orderId) async {
    final response = await _apiClient.dio.put('/delivery/orders/$orderId/deliver');
    if (response.statusCode == 200 && response.data['status'] == 'success') {
      return response.data['data'] as Map<String, dynamic>;
    }
    throw Exception(response.data['error'] ?? 'Failed to deliver order');
  }

  Future<void> verifyOtp(String orderId, String otp, {String otpType = 'delivery'}) async {
    final response = await _apiClient.dio.post('/delivery/orders/$orderId/verify-otp', data: {'otp': otp, 'otp_type': otpType});
    if (response.statusCode == 200 && response.data['status'] == 'success') {
      return;
    }
    throw Exception(response.data['error'] ?? 'OTP verification failed');
  }

  Future<List<Map<String, dynamic>>> getEarnings({int limit = 20, int offset = 0}) async {
    final response = await _apiClient.dio.get('/delivery/earnings', queryParameters: {'limit': limit, 'offset': offset});
    if (response.statusCode == 200 && response.data['status'] == 'success') {
      return (response.data['data'] as List<dynamic>).cast<Map<String, dynamic>>();
    }
    throw Exception(response.data['error'] ?? 'Failed to fetch earnings');
  }

  Future<Map<String, dynamic>> getEarningSummary() async {
    final response = await _apiClient.dio.get('/delivery/earnings/summary');
    if (response.statusCode == 200 && response.data['status'] == 'success') {
      return response.data['data'] as Map<String, dynamic>;
    }
    throw Exception(response.data['error'] ?? 'Failed to fetch earning summary');
  }

  Future<Map<String, dynamic>> getBankAccount() async {
    final response = await _apiClient.dio.get('/delivery/bank');
    if (response.statusCode == 200 && response.data['status'] == 'success') {
      return response.data['data'] as Map<String, dynamic>;
    }
    if (response.statusCode == 404) {
      throw Exception('Bank account not found');
    }
    throw Exception(response.data['error'] ?? 'Failed to fetch bank account');
  }

  Future<Map<String, dynamic>> upsertBankAccount(Map<String, dynamic> data) async {
    final response = await _apiClient.dio.post('/delivery/bank', data: data);
    if (response.statusCode == 200 && response.data['status'] == 'success') {
      return response.data['data'] as Map<String, dynamic>;
    }
    throw Exception(response.data['error'] ?? 'Failed to save bank account');
  }

  Future<void> deleteBankAccount() async {
    final response = await _apiClient.dio.delete('/delivery/bank');
    if (response.statusCode == 200 && response.data['status'] == 'success') {
      return;
    }
    throw Exception(response.data['error'] ?? 'Failed to delete bank account');
  }

  Future<Map<String, dynamic>> goOnline({String? deviceId, String? appVersion}) async {
    final body = <String, dynamic>{};
    if (deviceId != null) body['device_id'] = deviceId;
    if (appVersion != null) body['app_version'] = appVersion;
    final response = await _apiClient.dio.post('/delivery/presence/online', data: body);
    if (response.statusCode == 200 && response.data['status'] == 'success') {
      return response.data['data'] as Map<String, dynamic>;
    }
    throw Exception(response.data['error'] ?? 'Failed to go online');
  }

  Future<void> goOffline() async {
    final response = await _apiClient.dio.post('/delivery/presence/offline');
    if (response.statusCode == 200 && response.data['status'] == 'success') {
      return;
    }
    throw Exception(response.data['error'] ?? 'Failed to go offline');
  }

  Future<void> heartbeat() async {
    final response = await _apiClient.dio.post('/delivery/presence/heartbeat');
    if (response.statusCode == 200 && response.data['status'] == 'success') {
      return;
    }
    throw Exception(response.data['error'] ?? 'Heartbeat failed');
  }

  Future<Map<String, dynamic>> getMyPresence() async {
    final response = await _apiClient.dio.get('/delivery/presence/me');
    if (response.statusCode == 200 && response.data['status'] == 'success') {
      return response.data['data'] as Map<String, dynamic>;
    }
    throw Exception(response.data['error'] ?? 'Failed to fetch presence');
  }

  Future<Map<String, dynamic>> getOrderETA(String orderId) async {
    final response = await _apiClient.dio.get('/public/orders/$orderId/eta');
    if (response.statusCode == 200 && response.data['status'] == 'success') {
      return response.data['data'] as Map<String, dynamic>;
    }
    throw Exception(response.data['error'] ?? 'Failed to fetch ETA');
  }

  Future<Map<String, dynamic>> sendLocation({
    required double latitude,
    required double longitude,
    double accuracy = 0,
    double speed = 0,
    double bearing = 0,
    String? timestamp,
  }) async {
    final body = <String, dynamic>{
      'latitude': latitude,
      'longitude': longitude,
    };
    if (accuracy > 0) body['accuracy'] = accuracy;
    if (speed > 0) body['speed'] = speed;
    if (bearing >= 0) body['bearing'] = bearing;
    if (timestamp != null) body['timestamp'] = timestamp;
    final response = await _apiClient.dio.post('/delivery/location', data: body);
    if (response.statusCode == 200 && response.data['status'] == 'success') {
      return response.data['data'] as Map<String, dynamic>;
    }
    throw Exception(response.data['error'] ?? 'Failed to send location');
  }
}
