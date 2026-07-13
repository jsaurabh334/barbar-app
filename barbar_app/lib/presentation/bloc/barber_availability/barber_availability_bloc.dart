import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/barber_repository.dart';
import 'barber_availability_event.dart';
import 'barber_availability_state.dart';

class BarberAvailabilityBloc extends Bloc<BarberAvailabilityEvent, BarberAvailabilityState> {
  final BarberRepository _barberRepository;

  BarberAvailabilityBloc(this._barberRepository) : super(BarberAvailabilityInitial()) {
    on<FetchAvailability>(_onFetchAvailability);
    on<UpdateStatus>(_onUpdateStatus);
    on<SetWeeklySchedule>(_onSetWeeklySchedule);
    on<AddHoliday>(_onAddHoliday);
    on<UpdateBreakTime>(_onUpdateBreakTime);
    on<UpdateLocalScheduleEvent>(_onUpdateLocalSchedule);
  }

  void _onUpdateLocalSchedule(UpdateLocalScheduleEvent event, Emitter<BarberAvailabilityState> emit) {
    if (state is BarberAvailabilityLoaded) {
      final currentState = state as BarberAvailabilityLoaded;
      emit(BarberAvailabilityLoaded(
        currentStatus: currentState.currentStatus,
        isAvailable: currentState.isAvailable,
        weeklySchedule: event.schedule,
        holidays: currentState.holidays,
        breakStartTime: currentState.breakStartTime,
        breakEndTime: currentState.breakEndTime,
      ));
    }
  }

  Future<void> _onFetchAvailability(FetchAvailability event, Emitter<BarberAvailabilityState> emit) async {
    emit(BarberAvailabilityLoading());
    try {
      final dashboard = await _barberRepository.getDashboard();
      final barber = dashboard['barber'] as Map<String, dynamic>? ?? {};
      final schedule = await _barberRepository.getWeeklySchedule();
      final holidays = await _barberRepository.listHolidays();

      emit(BarberAvailabilityLoaded(
        currentStatus: barber['status'] as String? ?? 'active',
        isAvailable: barber['is_available'] as bool? ?? true,
        weeklySchedule: schedule,
        holidays: holidays,
        breakStartTime: barber['break_start_time'] as String?,
        breakEndTime: barber['break_end_time'] as String?,
      ));
    } catch (e) {
      emit(BarberAvailabilityFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onUpdateStatus(UpdateStatus event, Emitter<BarberAvailabilityState> emit) async {
    emit(BarberAvailabilityLoading());
    try {
      await _barberRepository.updateAvailability(isAvailable: event.isAvailable, status: event.status);
      emit(BarberAvailabilitySuccess('Status updated to ${event.status}'));
    } catch (e) {
      emit(BarberAvailabilityFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onSetWeeklySchedule(SetWeeklySchedule event, Emitter<BarberAvailabilityState> emit) async {
    emit(BarberAvailabilityLoading());
    try {
      await _barberRepository.setWeeklySchedule(event.schedule);
      emit(BarberAvailabilitySuccess('Weekly schedule updated'));
    } catch (e) {
      emit(BarberAvailabilityFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onAddHoliday(AddHoliday event, Emitter<BarberAvailabilityState> emit) async {
    emit(BarberAvailabilityLoading());
    try {
      await _barberRepository.addHoliday(date: event.date, reason: event.reason);
      emit(BarberAvailabilitySuccess('Holiday added'));
    } catch (e) {
      emit(BarberAvailabilityFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onUpdateBreakTime(UpdateBreakTime event, Emitter<BarberAvailabilityState> emit) async {
    emit(BarberAvailabilityLoading());
    try {
      await _barberRepository.updateProfile({
        'break_start_time': event.startTime,
        'break_end_time': event.endTime,
      });
      emit(BarberAvailabilitySuccess('Break time updated'));
    } catch (e) {
      emit(BarberAvailabilityFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
