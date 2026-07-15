import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/notification_model.dart';
import '../../../domain/repositories/notification_repository.dart';
import 'notification_event.dart';
import 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationRepository _repository;

  int _page = 1;
  static const int _limit = 20;
  final List<NotificationModel> _allNotifications = [];

  NotificationBloc(this._repository) : super(NotificationInitial()) {
    on<FetchNotifications>(_onFetch);
    on<MarkNotificationRead>(_onMarkRead);
    on<MarkAllNotificationsRead>(_onMarkAllRead);
    on<LoadMoreNotifications>(_onLoadMore);
    on<NewWebSocketNotification>(_onNewWebSocket);
  }

  Future<void> _onFetch(FetchNotifications event, Emitter<NotificationState> emit) async {
    if (event.refresh) {
      _page = 1;
      _allNotifications.clear();
    }

    emit(NotificationLoading());

    try {
      final notifications = await _repository.getNotifications(page: _page, limit: _limit);
      int unreadCount = 0;

      if (event.refresh) {
        try {
          unreadCount = await _repository.getUnreadCount();
        } catch (_) {}
      }

      _allNotifications.addAll(notifications);
      final hasMore = notifications.length >= _limit;

      emit(NotificationLoaded(
        notifications: List.from(_allNotifications),
        unreadCount: unreadCount,
        hasMore: hasMore,
      ));
    } catch (e) {
      emit(NotificationError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onMarkRead(MarkNotificationRead event, Emitter<NotificationState> emit) async {
    try {
      await _repository.markAsRead(event.id);
      if (state is NotificationLoaded) {
        final current = state as NotificationLoaded;
        final updated = current.notifications.map((n) {
          if (n.id == event.id) {
            return NotificationModel(
              id: n.id,
              userId: n.userId,
              title: n.title,
              body: n.body,
              type: n.type,
              data: n.data,
              image: n.image,
              link: n.link,
              isRead: true,
              readAt: n.readAt,
              createdAt: n.createdAt,
            );
          }
          return n;
        }).toList();

        emit(current.copyWith(
          notifications: updated,
          unreadCount: current.unreadCount > 0 ? current.unreadCount - 1 : 0,
        ));
      }
    } catch (_) {}
  }

  Future<void> _onMarkAllRead(MarkAllNotificationsRead event, Emitter<NotificationState> emit) async {
    try {
      await _repository.markAllAsRead();
      if (state is NotificationLoaded) {
        final current = state as NotificationLoaded;
        final updated = current.notifications.map((n) {
          return NotificationModel(
            id: n.id,
            userId: n.userId,
            title: n.title,
            body: n.body,
            type: n.type,
            data: n.data,
            image: n.image,
            link: n.link,
            isRead: true,
            readAt: n.readAt,
            createdAt: n.createdAt,
          );
        }).toList();

        emit(current.copyWith(notifications: updated, unreadCount: 0));
      }
    } catch (_) {}
  }

  Future<void> _onLoadMore(LoadMoreNotifications event, Emitter<NotificationState> emit) async {
    if (state is! NotificationLoaded) return;
    final current = state as NotificationLoaded;
    if (!current.hasMore) return;

    _page++;
    try {
      final notifications = await _repository.getNotifications(page: _page, limit: _limit);
      _allNotifications.addAll(notifications);
      final hasMore = notifications.length >= _limit;

      emit(current.copyWith(
        notifications: List.from(_allNotifications),
        hasMore: hasMore,
      ));
    } catch (_) {
      _page--;
    }
  }

  Future<void> _onNewWebSocket(NewWebSocketNotification event, Emitter<NotificationState> emit) async {
    try {
      final notif = NotificationModel.fromJson(event.payload);
      _allNotifications.insert(0, notif);

      if (state is NotificationLoaded) {
        final current = state as NotificationLoaded;
        emit(current.copyWith(
          notifications: List.from(_allNotifications),
          unreadCount: current.unreadCount + 1,
        ));
      }
    } catch (_) {}
  }
}
