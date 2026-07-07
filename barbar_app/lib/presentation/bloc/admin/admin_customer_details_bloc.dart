import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:barbar_app/domain/repositories/admin_repository.dart';
import 'package:barbar_app/data/models/admin_customer_details_model.dart';

// --- Events ---
abstract class AdminCustomerDetailsEvent extends Equatable {
  const AdminCustomerDetailsEvent();
  @override
  List<Object?> get props => [];
}

class LoadCustomerDetails extends AdminCustomerDetailsEvent {
  final String customerId;
  const LoadCustomerDetails(this.customerId);

  @override
  List<Object?> get props => [customerId];
}

class DetailBlockCustomer extends AdminCustomerDetailsEvent {
  final String customerId;
  const DetailBlockCustomer(this.customerId);

  @override
  List<Object?> get props => [customerId];
}

class DetailUnblockCustomer extends AdminCustomerDetailsEvent {
  final String customerId;
  const DetailUnblockCustomer(this.customerId);

  @override
  List<Object?> get props => [customerId];
}

class DetailDeleteCustomer extends AdminCustomerDetailsEvent {
  final String customerId;
  const DetailDeleteCustomer(this.customerId);

  @override
  List<Object?> get props => [customerId];
}

// --- States ---
abstract class AdminCustomerDetailsState extends Equatable {
  const AdminCustomerDetailsState();
  @override
  List<Object?> get props => [];
}

class AdminCustomerDetailsInitial extends AdminCustomerDetailsState {}

class AdminCustomerDetailsLoading extends AdminCustomerDetailsState {}

class AdminCustomerDetailsLoaded extends AdminCustomerDetailsState {
  final AdminCustomerDetailsModel details;

  const AdminCustomerDetailsLoaded(this.details);

  @override
  List<Object?> get props => [details];
}

class AdminCustomerDetailsError extends AdminCustomerDetailsState {
  final String message;
  const AdminCustomerDetailsError(this.message);

  @override
  List<Object?> get props => [message];
}

// --- Bloc ---
class AdminCustomerDetailsBloc extends Bloc<AdminCustomerDetailsEvent, AdminCustomerDetailsState> {
  final AdminRepository adminRepository;

  AdminCustomerDetailsBloc({required this.adminRepository}) : super(AdminCustomerDetailsInitial()) {
    on<LoadCustomerDetails>(_onLoadDetails);
    on<DetailBlockCustomer>(_onBlock);
    on<DetailUnblockCustomer>(_onUnblock);
    on<DetailDeleteCustomer>(_onDelete);
  }

  Future<void> _onLoadDetails(LoadCustomerDetails event, Emitter<AdminCustomerDetailsState> emit) async {
    emit(AdminCustomerDetailsLoading());
    try {
      final details = await adminRepository.getCustomerDetails(event.customerId);
      emit(AdminCustomerDetailsLoaded(details));
    } catch (e) {
      emit(AdminCustomerDetailsError(e.toString()));
    }
  }

  Future<void> _onBlock(DetailBlockCustomer event, Emitter<AdminCustomerDetailsState> emit) async {
    try {
      await adminRepository.blockCustomer(event.customerId);
      _updateStatus(event.customerId, 'blocked', emit);
    } catch (e) {
      // ignored
    }
  }

  Future<void> _onUnblock(DetailUnblockCustomer event, Emitter<AdminCustomerDetailsState> emit) async {
    try {
      await adminRepository.unblockCustomer(event.customerId);
      _updateStatus(event.customerId, 'active', emit);
    } catch (e) {
      // ignored
    }
  }

  Future<void> _onDelete(DetailDeleteCustomer event, Emitter<AdminCustomerDetailsState> emit) async {
    try {
      await adminRepository.deleteCustomer(event.customerId);
      _updateStatus(event.customerId, 'deleted', emit);
    } catch (e) {
      // ignored
    }
  }

  void _updateStatus(String customerId, String status, Emitter<AdminCustomerDetailsState> emit) {
    if (state is AdminCustomerDetailsLoaded) {
      final current = (state as AdminCustomerDetailsLoaded).details;
      // Copy customer model and update status
      final updatedCustomer = current.customer.copyWith(status: status);
      
      final updatedDetails = AdminCustomerDetailsModel(
        customer: updatedCustomer,
        walletBalance: current.walletBalance,
        transactions: current.transactions,
        bookings: current.bookings,
        reviews: current.reviews,
        totalBookings: current.totalBookings,
        completedBookings: current.completedBookings,
        cancelledBookings: current.cancelledBookings,
        spent: current.spent,
        rating: current.rating,
      );

      emit(AdminCustomerDetailsLoaded(updatedDetails));
    }
  }
}
