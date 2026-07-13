import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/barber_repository.dart';
import 'barber_profile_event.dart';
import 'barber_profile_state.dart';

class BarberProfileBloc extends Bloc<BarberProfileEvent, BarberProfileState> {
  final BarberRepository _barberRepository;

  BarberProfileBloc(this._barberRepository) : super(BarberProfileInitial()) {
    on<FetchBarberProfile>(_onFetchProfile);
    on<UpdateBarberProfile>(_onUpdateProfile);
  }

  Future<void> _onFetchProfile(FetchBarberProfile event, Emitter<BarberProfileState> emit) async {
    emit(BarberProfileLoading());
    try {
      final dashboard = await _barberRepository.getDashboard();
      final barber = dashboard['barber'] as Map<String, dynamic>? ?? {};
      emit(BarberProfileLoaded(barber));
    } catch (e) {
      emit(BarberProfileFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onUpdateProfile(UpdateBarberProfile event, Emitter<BarberProfileState> emit) async {
    emit(BarberProfileLoading());
    try {
      await _barberRepository.updateProfile(event.data);
      emit(BarberProfileSuccess('Profile updated successfully'));
      final dashboard = await _barberRepository.getDashboard();
      final barber = dashboard['barber'] as Map<String, dynamic>? ?? {};
      emit(BarberProfileLoaded(barber));
    } catch (e) {
      emit(BarberProfileFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
