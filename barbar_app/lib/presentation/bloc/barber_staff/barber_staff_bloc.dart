import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/barber_repository.dart';
import '../../../data/models/staff_model.dart';
import 'barber_staff_event.dart';
import 'barber_staff_state.dart';

class BarberStaffBloc extends Bloc<BarberStaffEvent, BarberStaffState> {
  final BarberRepository _repository;

  BarberStaffBloc(this._repository) : super(BarberStaffInitial()) {
    on<FetchStaff>(_onFetchStaff);
    on<AddStaff>(_onAddStaff);
    on<UpdateStaff>(_onUpdateStaff);
    on<ArchiveStaff>(_onArchiveStaff);
  }

  Future<void> _onFetchStaff(FetchStaff event, Emitter<BarberStaffState> emit) async {
    emit(BarberStaffLoading());
    try {
      final rawStaff = await _repository.getStaff();
      final staffList = rawStaff.map((e) => StaffModel.fromJson(e)).toList();
      emit(BarberStaffLoaded(staffList));
    } catch (e) {
      emit(BarberStaffError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onAddStaff(AddStaff event, Emitter<BarberStaffState> emit) async {
    emit(BarberStaffLoading());
    try {
      await _repository.addStaff(event.staffData);
      emit(BarberStaffOperationSuccess('Staff member added successfully'));
      add(FetchStaff());
    } catch (e) {
      emit(BarberStaffError(e.toString().replaceAll('Exception: ', '')));
      add(FetchStaff()); // Reload list just in case
    }
  }

  Future<void> _onUpdateStaff(UpdateStaff event, Emitter<BarberStaffState> emit) async {
    emit(BarberStaffLoading());
    try {
      await _repository.updateStaff(event.staffId, event.updates);
      emit(BarberStaffOperationSuccess('Staff details updated'));
      add(FetchStaff());
    } catch (e) {
      emit(BarberStaffError(e.toString().replaceAll('Exception: ', '')));
      add(FetchStaff());
    }
  }

  Future<void> _onArchiveStaff(ArchiveStaff event, Emitter<BarberStaffState> emit) async {
    emit(BarberStaffLoading());
    try {
      await _repository.archiveStaff(event.staffId);
      emit(BarberStaffOperationSuccess('Staff member archived'));
      add(FetchStaff());
    } catch (e) {
      emit(BarberStaffError(e.toString().replaceAll('Exception: ', '')));
      add(FetchStaff());
    }
  }
}
