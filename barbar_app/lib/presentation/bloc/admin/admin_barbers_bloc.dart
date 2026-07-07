import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:barbar_app/domain/repositories/admin_repository.dart';
import 'package:barbar_app/data/models/barber_model.dart';
import 'package:equatable/equatable.dart';

// Events
abstract class AdminBarbersEvent extends Equatable {
  const AdminBarbersEvent();
  @override
  List<Object> get props => [];
}

class LoadPendingBarbers extends AdminBarbersEvent {}
class LoadActiveBarbers extends AdminBarbersEvent {}

class ApproveBarberEvent extends AdminBarbersEvent {
  final String id;
  const ApproveBarberEvent(this.id);
  @override
  List<Object> get props => [id];
}

class RejectBarberEvent extends AdminBarbersEvent {
  final String id;
  final String reason;
  const RejectBarberEvent(this.id, this.reason);
  @override
  List<Object> get props => [id, reason];
}

class SuspendBarberEvent extends AdminBarbersEvent {
  final String id;
  const SuspendBarberEvent(this.id);
  @override
  List<Object> get props => [id];
}

class ActivateBarberEvent extends AdminBarbersEvent {
  final String id;
  const ActivateBarberEvent(this.id);
  @override
  List<Object> get props => [id];
}

// States
abstract class AdminBarbersState extends Equatable {
  const AdminBarbersState();
  @override
  List<Object> get props => [];
}

class AdminBarbersInitial extends AdminBarbersState {}
class AdminBarbersLoading extends AdminBarbersState {}
class AdminBarbersLoaded extends AdminBarbersState {
  final List<BarberModel> barbers;
  const AdminBarbersLoaded(this.barbers);
  @override
  List<Object> get props => [barbers];
}
class AdminBarbersError extends AdminBarbersState {
  final String message;
  const AdminBarbersError(this.message);
  @override
  List<Object> get props => [message];
}

class AdminBarberActionSuccess extends AdminBarbersState {
  final String message;
  const AdminBarberActionSuccess(this.message);
  @override
  List<Object> get props => [message];
}

// Bloc
class AdminBarbersBloc extends Bloc<AdminBarbersEvent, AdminBarbersState> {
  final AdminRepository adminRepository;

  AdminBarbersBloc({required this.adminRepository}) : super(AdminBarbersInitial()) {
    on<LoadPendingBarbers>(_onLoadPendingBarbers);
    on<LoadActiveBarbers>(_onLoadActiveBarbers);
    on<ApproveBarberEvent>(_onApproveBarber);
    on<RejectBarberEvent>(_onRejectBarber);
    on<SuspendBarberEvent>(_onSuspendBarber);
    on<ActivateBarberEvent>(_onActivateBarber);
  }

  Future<void> _onLoadPendingBarbers(LoadPendingBarbers event, Emitter<AdminBarbersState> emit) async {
    emit(AdminBarbersLoading());
    try {
      final barbers = await adminRepository.getBarbers(verificationStatus: 'pending');
      emit(AdminBarbersLoaded(barbers));
    } catch (e) {
      emit(AdminBarbersError(e.toString()));
    }
  }

  Future<void> _onLoadActiveBarbers(LoadActiveBarbers event, Emitter<AdminBarbersState> emit) async {
    emit(AdminBarbersLoading());
    try {
      final barbers = await adminRepository.getBarbers(verificationStatus: 'approved');
      emit(AdminBarbersLoaded(barbers));
    } catch (e) {
      emit(AdminBarbersError(e.toString()));
    }
  }

  Future<void> _onApproveBarber(ApproveBarberEvent event, Emitter<AdminBarbersState> emit) async {
    try {
      await adminRepository.approveBarber(event.id);
      emit(const AdminBarberActionSuccess("Barber approved successfully"));
      add(LoadPendingBarbers()); // Reload pending list
    } catch (e) {
      emit(AdminBarbersError(e.toString()));
    }
  }

  Future<void> _onRejectBarber(RejectBarberEvent event, Emitter<AdminBarbersState> emit) async {
    try {
      await adminRepository.rejectBarber(event.id, event.reason);
      emit(const AdminBarberActionSuccess("Barber rejected successfully"));
      add(LoadPendingBarbers());
    } catch (e) {
      emit(AdminBarbersError(e.toString()));
    }
  }

  Future<void> _onSuspendBarber(SuspendBarberEvent event, Emitter<AdminBarbersState> emit) async {
    try {
      await adminRepository.suspendBarber(event.id);
      emit(const AdminBarberActionSuccess("Barber suspended"));
      add(LoadActiveBarbers());
    } catch (e) {
      emit(AdminBarbersError(e.toString()));
    }
  }

  Future<void> _onActivateBarber(ActivateBarberEvent event, Emitter<AdminBarbersState> emit) async {
    try {
      await adminRepository.activateBarber(event.id);
      emit(const AdminBarberActionSuccess("Barber activated"));
      add(LoadActiveBarbers());
    } catch (e) {
      emit(AdminBarbersError(e.toString()));
    }
  }
}
