import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:barbar_app/domain/repositories/admin_repository.dart';
import 'package:barbar_app/data/models/barber_model.dart';
import 'package:barbar_app/data/models/kyc_document_model.dart';

// --- Events ---
abstract class AdminBarberDetailsEvent extends Equatable {
  const AdminBarberDetailsEvent();
  @override
  List<Object> get props => [];
}

class LoadBarberDetails extends AdminBarberDetailsEvent {
  final String barberId;
  const LoadBarberDetails(this.barberId);
  @override
  List<Object> get props => [barberId];
}

class ApproveBarberDetailsEvent extends AdminBarberDetailsEvent {
  final String barberId;
  const ApproveBarberDetailsEvent(this.barberId);
  @override
  List<Object> get props => [barberId];
}

class RejectBarberDetailsEvent extends AdminBarberDetailsEvent {
  final String barberId;
  final String reason;
  const RejectBarberDetailsEvent(this.barberId, this.reason);
  @override
  List<Object> get props => [barberId, reason];
}

class SuspendBarberDetailsEvent extends AdminBarberDetailsEvent {
  final String barberId;
  const SuspendBarberDetailsEvent(this.barberId);
  @override
  List<Object> get props => [barberId];
}

class ApproveKycDocumentEvent extends AdminBarberDetailsEvent {
  final String documentId;
  const ApproveKycDocumentEvent(this.documentId);
  @override
  List<Object> get props => [documentId];
}

class RejectKycDocumentEvent extends AdminBarberDetailsEvent {
  final String documentId;
  final String reason;
  const RejectKycDocumentEvent(this.documentId, this.reason);
  @override
  List<Object> get props => [documentId, reason];
}

// --- States ---
abstract class AdminBarberDetailsState extends Equatable {
  const AdminBarberDetailsState();
  @override
  List<Object?> get props => [];
}

class AdminBarberDetailsInitial extends AdminBarberDetailsState {}

class AdminBarberDetailsLoading extends AdminBarberDetailsState {}

class AdminBarberDetailsLoaded extends AdminBarberDetailsState {
  final BarberModel barber;
  final List<KycDocumentModel> kycDocuments;

  const AdminBarberDetailsLoaded(this.barber, {this.kycDocuments = const []});
  @override
  List<Object?> get props => [barber, kycDocuments];
}

class AdminBarberDetailsError extends AdminBarberDetailsState {
  final String message;
  const AdminBarberDetailsError(this.message);
  @override
  List<Object?> get props => [message];
}

class AdminBarberDetailsActionSuccess extends AdminBarberDetailsState {
  final String message;
  final BarberModel barber;
  const AdminBarberDetailsActionSuccess(this.message, this.barber);
  @override
  List<Object?> get props => [message, barber];
}

// --- Bloc ---
class AdminBarberDetailsBloc extends Bloc<AdminBarberDetailsEvent, AdminBarberDetailsState> {
  final AdminRepository adminRepository;

  AdminBarberDetailsBloc({required this.adminRepository}) : super(AdminBarberDetailsInitial()) {
    on<LoadBarberDetails>(_onLoadBarberDetails);
    on<ApproveBarberDetailsEvent>(_onApproveBarber);
    on<RejectBarberDetailsEvent>(_onRejectBarber);
    on<SuspendBarberDetailsEvent>(_onSuspendBarber);
    on<ApproveKycDocumentEvent>(_onApproveKyc);
    on<RejectKycDocumentEvent>(_onRejectKyc);
  }

  Future<void> _onLoadBarberDetails(LoadBarberDetails event, Emitter<AdminBarberDetailsState> emit) async {
    emit(AdminBarberDetailsLoading());
    try {
      final barber = await adminRepository.getBarberDetails(event.barberId);
      List<KycDocumentModel> docs = [];
      if (barber.userId != null) {
        docs = await adminRepository.getKycDocuments(barber.userId!);
      } else {
        // Fallback for mocked barbers without userId
        docs = await adminRepository.getKycDocuments('u1');
      }
      emit(AdminBarberDetailsLoaded(barber, kycDocuments: docs));
    } catch (e) {
      emit(AdminBarberDetailsError(e.toString()));
    }
  }

  Future<void> _onApproveBarber(ApproveBarberDetailsEvent event, Emitter<AdminBarberDetailsState> emit) async {
    final currentState = state;
    if (currentState is AdminBarberDetailsLoaded) {
      try {
        await adminRepository.approveBarber(event.barberId);
        final updatedBarber = currentState.barber.copyWith(verificationStatus: 'approved', status: 'active');
        emit(AdminBarberDetailsActionSuccess("Barber approved successfully.", updatedBarber));
        emit(AdminBarberDetailsLoaded(updatedBarber));
      } catch (e) {
        emit(AdminBarberDetailsError(e.toString()));
      }
    }
  }

  Future<void> _onRejectBarber(RejectBarberDetailsEvent event, Emitter<AdminBarberDetailsState> emit) async {
    final currentState = state;
    if (currentState is AdminBarberDetailsLoaded) {
      try {
        await adminRepository.rejectBarber(event.barberId, event.reason);
        final updatedBarber = currentState.barber.copyWith(verificationStatus: 'rejected', status: 'inactive');
        emit(AdminBarberDetailsActionSuccess("Barber application rejected.", updatedBarber));
        emit(AdminBarberDetailsLoaded(updatedBarber));
      } catch (e) {
        emit(AdminBarberDetailsError(e.toString()));
      }
    }
  }

  Future<void> _onSuspendBarber(SuspendBarberDetailsEvent event, Emitter<AdminBarberDetailsState> emit) async {
    final currentState = state;
    if (currentState is AdminBarberDetailsLoaded) {
      try {
        await adminRepository.suspendBarber(event.barberId);
        final updatedBarber = currentState.barber.copyWith(status: 'suspended');
        emit(AdminBarberDetailsActionSuccess("Barber suspended successfully.", updatedBarber));
        emit(AdminBarberDetailsLoaded(updatedBarber));
      } catch (e) {
        emit(AdminBarberDetailsError(e.toString()));
      }
    }
  }

  Future<void> _onApproveKyc(ApproveKycDocumentEvent event, Emitter<AdminBarberDetailsState> emit) async {
    final currentState = state;
    if (currentState is AdminBarberDetailsLoaded) {
      try {
        await adminRepository.approveKycDocument(event.documentId);
        final updatedDocs = currentState.kycDocuments.map((d) => d.id == event.documentId ? d.copyWith(status: 'approved') : d).toList();
        emit(AdminBarberDetailsActionSuccess('KYC Document Approved', currentState.barber));
        emit(AdminBarberDetailsLoaded(currentState.barber, kycDocuments: updatedDocs));
      } catch (e) {
        emit(AdminBarberDetailsError(e.toString()));
        emit(currentState);
      }
    }
  }

  Future<void> _onRejectKyc(RejectKycDocumentEvent event, Emitter<AdminBarberDetailsState> emit) async {
    final currentState = state;
    if (currentState is AdminBarberDetailsLoaded) {
      try {
        await adminRepository.rejectKycDocument(event.documentId, event.reason);
        final updatedDocs = currentState.kycDocuments.map((d) => d.id == event.documentId ? d.copyWith(status: 'rejected', rejectReason: event.reason) : d).toList();
        emit(AdminBarberDetailsActionSuccess('KYC Document Rejected', currentState.barber));
        emit(AdminBarberDetailsLoaded(currentState.barber, kycDocuments: updatedDocs));
      } catch (e) {
        emit(AdminBarberDetailsError(e.toString()));
        emit(currentState);
      }
    }
  }
}
