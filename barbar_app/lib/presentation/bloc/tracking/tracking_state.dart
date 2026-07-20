import 'package:equatable/equatable.dart';
import '../../../data/models/tracking/tracking_response.dart';

abstract class TrackingState extends Equatable {
  const TrackingState();

  @override
  List<Object?> get props => [];
}

class TrackingInitial extends TrackingState {
  const TrackingInitial();
}

class TrackingLoading extends TrackingState {
  const TrackingLoading();
}

class TrackingLoaded extends TrackingState {
  final TrackingResponse response;
  final bool isLive;

  const TrackingLoaded(this.response, {this.isLive = true});

  @override
  List<Object?> get props => [response, isLive];
}

class TrackingOffline extends TrackingState {
  final TrackingResponse? lastResponse;

  const TrackingOffline(this.lastResponse);

  @override
  List<Object?> get props => [lastResponse];
}

class TrackingFailure extends TrackingState {
  final String message;

  const TrackingFailure(this.message);

  @override
  List<Object?> get props => [message];
}
