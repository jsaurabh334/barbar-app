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
      final result = await _barberRepository.getProfile();
      final barber = result['barber'] as Map<String, dynamic>? ?? {};
      final profileCompleted = result['profile_completed'] as bool? ?? false;
      emit(BarberProfileLoaded(barber, profileCompleted));
    } catch (e) {
      emit(BarberProfileFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onUpdateProfile(UpdateBarberProfile event, Emitter<BarberProfileState> emit) async {
    emit(BarberProfileLoading());
    try {
      final result = await _barberRepository.updateProfile(event.data);
      final barber = result['barber'] as Map<String, dynamic>? ?? {};
      final profileCompleted = result['profile_completed'] as bool? ?? false;
      emit(BarberProfileSuccess('Profile updated successfully'));
      emit(BarberProfileLoaded(barber, profileCompleted));
    } catch (e) {
      emit(BarberProfileFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
