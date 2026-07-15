import '../../../core/network/api_client.dart';
import '../../models/notification_model.dart';

class NotificationRemoteDataSource {
  final ApiClient _apiClient;

  NotificationRemoteDataSource(this._apiClient);

  Future<List<NotificationModel>> getNotifications({int page = 1, int limit = 20}) async {
    final response = await _apiClient.dio.get('/notifications', queryParameters: {'page': page, 'limit': limit});
    if (response.statusCode == 200 && (response.data['status'] == 'success' || response.data['status'] == 'created')) {
      final rawList = (response.data['data'] as List<dynamic>?) ?? [];
      return rawList.map((e) => NotificationModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception(response.data['error'] ?? 'Failed to fetch notifications');
  }

  Future<void> markAsRead(String id) async {
    await _apiClient.dio.put('/notifications/$id/read');
  }

  Future<void> markAllAsRead() async {
    await _apiClient.dio.put('/notifications/read-all');
  }

  Future<int> getUnreadCount() async {
    final response = await _apiClient.dio.get('/notifications', queryParameters: {'page': 1, 'limit': 1, 'filter': 'unread'});
    if (response.statusCode == 200 && response.data['status'] == 'success') {
      return (response.data['total'] as num?)?.toInt() ?? 0;
    }
    return 0;
  }

  Future<void> registerDeviceToken(String token, String platform) async {
    await _apiClient.dio.post('/devices', data: {'token': token, 'platform': platform});
  }

  Future<void> unregisterDeviceToken(String token) async {
    await _apiClient.dio.delete('/devices/$token');
  }
}
