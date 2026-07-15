import '../../data/models/notification_model.dart';

abstract class NotificationRepository {
  Future<List<NotificationModel>> getNotifications({int page = 1, int limit = 20});
  Future<void> markAsRead(String id);
  Future<void> markAllAsRead();
  Future<int> getUnreadCount();
  Future<void> registerDeviceToken(String token, String platform);
  Future<void> unregisterDeviceToken(String token);
}
