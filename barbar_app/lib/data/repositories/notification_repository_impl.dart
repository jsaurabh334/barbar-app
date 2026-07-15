import '../../domain/repositories/notification_repository.dart';
import '../datasources/remote/notification_remote_datasource.dart';
import '../models/notification_model.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource _remoteDataSource;

  NotificationRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<NotificationModel>> getNotifications({int page = 1, int limit = 20}) {
    return _remoteDataSource.getNotifications(page: page, limit: limit);
  }

  @override
  Future<void> markAsRead(String id) {
    return _remoteDataSource.markAsRead(id);
  }

  @override
  Future<void> markAllAsRead() {
    return _remoteDataSource.markAllAsRead();
  }

  @override
  Future<int> getUnreadCount() {
    return _remoteDataSource.getUnreadCount();
  }

  @override
  Future<void> registerDeviceToken(String token, String platform) {
    return _remoteDataSource.registerDeviceToken(token, platform);
  }

  @override
  Future<void> unregisterDeviceToken(String token) {
    return _remoteDataSource.unregisterDeviceToken(token);
  }
}
