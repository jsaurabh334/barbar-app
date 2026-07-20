import 'package:equatable/equatable.dart';

abstract class TrackingEvent extends Equatable {
  const TrackingEvent();

  @override
  List<Object?> get props => [];
}

class StartTracking extends TrackingEvent {
  final String orderId;
  const StartTracking(this.orderId);

  @override
  List<Object?> get props => [orderId];
}

class TrackingUpdated extends TrackingEvent {
  final dynamic data;
  const TrackingUpdated(this.data);

  @override
  List<Object?> get props => [data];
}

class StopTracking extends TrackingEvent {
  const StopTracking();
}
