import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/directory_repository.dart';
import 'directory_event.dart';
import 'directory_state.dart';

class DirectoryBloc extends Bloc<DirectoryEvent, DirectoryState> {
  final DirectoryRepository _directoryRepository;

  DirectoryBloc(this._directoryRepository) : super(DirectoryInitial()) {
    on<FetchNearbyBarbers>(_onFetchNearbyBarbers);
    on<UpdateBarberQueue>(_onUpdateBarberQueue);
  }

  Future<void> _onFetchNearbyBarbers(
    FetchNearbyBarbers event,
    Emitter<DirectoryState> emit,
  ) async {
    emit(DirectoryLoading());
    try {
      final barbers = await _directoryRepository.getNearbyBarbers(
        latitude: event.latitude,
        longitude: event.longitude,
        radius: event.radius,
        search: event.search,
      );
      emit(DirectoryLoaded(barbers));
    } catch (e) {
      emit(DirectoryFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  void _onUpdateBarberQueue(UpdateBarberQueue event, Emitter<DirectoryState> emit) {
    if (state is DirectoryLoaded) {
      final currentList = (state as DirectoryLoaded).barbers;
      final updatedList = currentList.map((barber) {
        if (barber.id == event.barberId) {
          return barber.copyWith(
            currentQueueLength: event.currentQueueLength,
            averageWaitTime: event.averageWaitTime,
          );
        }
        return barber;
      }).toList();
      emit(DirectoryLoaded(updatedList));
    }
  }
}
