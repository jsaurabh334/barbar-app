import 'package:equatable/equatable.dart';

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object?> get props => [];
}

class FetchNotifications extends NotificationEvent {
  final bool refresh;

  const FetchNotifications({this.refresh = false});

  @override
  List<Object?> get props => [refresh];
}

class MarkNotificationRead extends NotificationEvent {
  final String id;

  const MarkNotificationRead(this.id);

  @override
  List<Object?> get props => [id];
}

class MarkAllNotificationsRead extends NotificationEvent {}

class LoadMoreNotifications extends NotificationEvent {}

class NewWebSocketNotification extends NotificationEvent {
  final Map<String, dynamic> payload;

  const NewWebSocketNotification(this.payload);

  @override
  List<Object?> get props => [payload];
}
