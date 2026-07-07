import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:barbar_app/domain/repositories/admin_repository.dart';
import 'package:barbar_app/data/models/delivery_partner_model.dart';

// --- Events ---
abstract class AdminDeliveryEvent extends Equatable {
  const AdminDeliveryEvent();
  @override
  List<Object?> get props => [];
}

class LoadDeliveryPartners extends AdminDeliveryEvent {
  final int page;
  final String? searchQuery;

  const LoadDeliveryPartners({this.page = 1, this.searchQuery});

  @override
  List<Object?> get props => [page, searchQuery];
}

class UpdateDeliveryStatus extends AdminDeliveryEvent {
  final String partnerId;
  final String status;
  const UpdateDeliveryStatus(this.partnerId, this.status);

  @override
  List<Object?> get props => [partnerId, status];
}

// --- States ---
abstract class AdminDeliveryState extends Equatable {
  const AdminDeliveryState();
  @override
  List<Object?> get props => [];
}

class AdminDeliveryInitial extends AdminDeliveryState {}

class AdminDeliveryLoading extends AdminDeliveryState {}

class AdminDeliveryLoaded extends AdminDeliveryState {
  final List<DeliveryPartnerModel> partners;
  final int currentPage;
  final bool hasReachedMax;

  const AdminDeliveryLoaded({
    required this.partners,
    required this.currentPage,
    this.hasReachedMax = false,
  });

  @override
  List<Object?> get props => [partners, currentPage, hasReachedMax];
}

class AdminDeliveryError extends AdminDeliveryState {
  final String message;
  const AdminDeliveryError(this.message);

  @override
  List<Object?> get props => [message];
}

// --- Bloc ---
class AdminDeliveryBloc extends Bloc<AdminDeliveryEvent, AdminDeliveryState> {
  final AdminRepository adminRepository;

  AdminDeliveryBloc({required this.adminRepository}) : super(AdminDeliveryInitial()) {
    on<LoadDeliveryPartners>(_onLoadDeliveryPartners);
    on<UpdateDeliveryStatus>(_onUpdateDeliveryStatus);
  }

  Future<void> _onLoadDeliveryPartners(LoadDeliveryPartners event, Emitter<AdminDeliveryState> emit) async {
    if (event.page == 1) {
      emit(AdminDeliveryLoading());
    }
    try {
      final partners = await adminRepository.getDeliveryPartners(page: event.page, search: event.searchQuery);
      
      if (state is AdminDeliveryLoaded && event.page > 1) {
        final currentState = state as AdminDeliveryLoaded;
        emit(AdminDeliveryLoaded(
          partners: currentState.partners + partners,
          currentPage: event.page,
          hasReachedMax: partners.isEmpty || partners.length < 20,
        ));
      } else {
        emit(AdminDeliveryLoaded(
          partners: partners,
          currentPage: event.page,
          hasReachedMax: partners.isEmpty || partners.length < 20,
        ));
      }
    } catch (e) {
      emit(AdminDeliveryError(e.toString()));
    }
  }

  Future<void> _onUpdateDeliveryStatus(UpdateDeliveryStatus event, Emitter<AdminDeliveryState> emit) async {
    if (state is AdminDeliveryLoaded) {
      final currentState = state as AdminDeliveryLoaded;
      try {
        await adminRepository.updateDeliveryPartnerStatus(event.partnerId, event.status);
        
        final updatedPartners = currentState.partners.map((p) {
          if (p.id == event.partnerId) {
            return p.copyWith(availabilityStatus: event.status);
          }
          return p;
        }).toList();

        emit(AdminDeliveryLoaded(
          partners: updatedPartners,
          currentPage: currentState.currentPage,
          hasReachedMax: currentState.hasReachedMax,
        ));
      } catch (e) {
        emit(AdminDeliveryError('Failed to update status: $e'));
        emit(currentState);
      }
    }
  }
}
