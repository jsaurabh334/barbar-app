import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/barber_repository.dart';
import 'barber_services_event.dart';
import 'barber_services_state.dart';

class BarberServicesBloc extends Bloc<BarberServicesEvent, BarberServicesState> {
  final BarberRepository _barberRepository;

  BarberServicesBloc(this._barberRepository) : super(BarberServicesInitial()) {
    on<FetchServices>(_onFetchServices);
    on<AddService>(_onAddService);
    on<UpdateService>(_onUpdateService);
    on<DeleteService>(_onDeleteService);
    on<ToggleActive>(_onToggleActive);
  }

  Future<void> _onFetchServices(FetchServices event, Emitter<BarberServicesState> emit) async {
    emit(BarberServicesLoading());
    try {
      final services = await _barberRepository.getBarberServices();
      emit(BarberServicesLoaded(services));
    } catch (e) {
      emit(BarberServicesFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onAddService(AddService event, Emitter<BarberServicesState> emit) async {
    emit(BarberServicesLoading());
    try {
      await _barberRepository.addService(event.data);
      final services = await _barberRepository.getBarberServices();
      emit(BarberServicesSuccess('Service added successfully'));
      emit(BarberServicesLoaded(services));
    } catch (e) {
      emit(BarberServicesFailure(e.toString().replaceAll('Exception: ', '')));
      add(FetchServices());
    }
  }

  Future<void> _onUpdateService(UpdateService event, Emitter<BarberServicesState> emit) async {
    emit(BarberServicesLoading());
    try {
      await _barberRepository.updateService(event.serviceId, event.data);
      final services = await _barberRepository.getBarberServices();
      emit(BarberServicesSuccess('Service updated successfully'));
      emit(BarberServicesLoaded(services));
    } catch (e) {
      emit(BarberServicesFailure(e.toString().replaceAll('Exception: ', '')));
      add(FetchServices());
    }
  }

  Future<void> _onDeleteService(DeleteService event, Emitter<BarberServicesState> emit) async {
    emit(BarberServicesLoading());
    try {
      await _barberRepository.updateService(event.serviceId, {'is_active': false});
      final services = await _barberRepository.getBarberServices();
      emit(BarberServicesSuccess('Service archived successfully'));
      emit(BarberServicesLoaded(services));
    } catch (e) {
      emit(BarberServicesFailure(e.toString().replaceAll('Exception: ', '')));
      add(FetchServices());
    }
  }

  Future<void> _onToggleActive(ToggleActive event, Emitter<BarberServicesState> emit) async {
    emit(BarberServicesLoading());
    try {
      await _barberRepository.updateService(event.serviceId, {'is_active': event.isActive});
      final services = await _barberRepository.getBarberServices();
      emit(BarberServicesSuccess(event.isActive ? 'Service activated' : 'Service archived'));
      emit(BarberServicesLoaded(services));
    } catch (e) {
      emit(BarberServicesFailure(e.toString().replaceAll('Exception: ', '')));
      add(FetchServices());
    }
  }
}
