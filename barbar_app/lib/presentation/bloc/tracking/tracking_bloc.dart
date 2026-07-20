import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/tracking/tracking_response.dart';
import '../../../domain/repositories/tracking_repository.dart';
import 'tracking_event.dart';
import 'tracking_state.dart';

class TrackingBloc extends Bloc<TrackingEvent, TrackingState> {
  final TrackingRepository _repository;
  StreamSubscription<TrackingResponse>? _updateSub;

  TrackingBloc(this._repository) : super(const TrackingInitial()) {
    on<StartTracking>(_onStartTracking);
    on<TrackingUpdated>(_onTrackingUpdated);
    on<StopTracking>(_onStopTracking);
  }

  Future<void> _onStartTracking(StartTracking event, Emitter<TrackingState> emit) async {
    emit(const TrackingLoading());

    await _updateSub?.cancel();
    _updateSub = _repository.trackingUpdates(event.orderId).listen(
      (response) {
        add(TrackingUpdated(response));
      },
      onError: (err) {
        emit(TrackingFailure(err.toString()));
      },
    );
  }

  void _onTrackingUpdated(TrackingUpdated event, Emitter<TrackingState> emit) {
    if (event.data is TrackingResponse) {
      emit(TrackingLoaded(event.data, isLive: true));
    }
  }

  void _onStopTracking(StopTracking event, Emitter<TrackingState> emit) {
    _updateSub?.cancel();
    _repository.dispose();
    emit(const TrackingInitial());
  }

  @override
  Future<void> close() {
    _updateSub?.cancel();
    _repository.dispose();
    return super.close();
  }
}
