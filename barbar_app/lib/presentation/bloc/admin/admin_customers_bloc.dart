import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:barbar_app/domain/repositories/admin_repository.dart';
import 'package:barbar_app/data/models/user_model.dart';

// --- Events ---
abstract class AdminCustomersEvent extends Equatable {
  const AdminCustomersEvent();
  @override
  List<Object?> get props => [];
}

class LoadCustomers extends AdminCustomersEvent {
  final int page;
  final String? searchQuery;
  final String? status;

  const LoadCustomers({this.page = 1, this.searchQuery, this.status});

  @override
  List<Object?> get props => [page, searchQuery, status];
}

class BlockCustomer extends AdminCustomersEvent {
  final String customerId;
  const BlockCustomer(this.customerId);

  @override
  List<Object?> get props => [customerId];
}

class UnblockCustomer extends AdminCustomersEvent {
  final String customerId;
  const UnblockCustomer(this.customerId);

  @override
  List<Object?> get props => [customerId];
}

class DeleteCustomer extends AdminCustomersEvent {
  final String customerId;
  const DeleteCustomer(this.customerId);

  @override
  List<Object?> get props => [customerId];
}

// --- States ---
abstract class AdminCustomersState extends Equatable {
  const AdminCustomersState();
  @override
  List<Object?> get props => [];
}

class AdminCustomersInitial extends AdminCustomersState {}

class AdminCustomersLoading extends AdminCustomersState {}

class AdminCustomersLoaded extends AdminCustomersState {
  final List<UserModel> customers;
  final int currentPage;
  final bool hasReachedMax;

  const AdminCustomersLoaded({
    required this.customers,
    required this.currentPage,
    this.hasReachedMax = false,
  });

  @override
  List<Object?> get props => [customers, currentPage, hasReachedMax];
}

class AdminCustomersError extends AdminCustomersState {
  final String message;
  const AdminCustomersError(this.message);

  @override
  List<Object?> get props => [message];
}

// --- Bloc ---
class AdminCustomersBloc extends Bloc<AdminCustomersEvent, AdminCustomersState> {
  final AdminRepository adminRepository;

  AdminCustomersBloc({required this.adminRepository}) : super(AdminCustomersInitial()) {
    on<LoadCustomers>(_onLoadCustomers);
    on<BlockCustomer>(_onBlockCustomer);
    on<UnblockCustomer>(_onUnblockCustomer);
    on<DeleteCustomer>(_onDeleteCustomer);
  }

  Future<void> _onLoadCustomers(LoadCustomers event, Emitter<AdminCustomersState> emit) async {
    if (event.page == 1) {
      emit(AdminCustomersLoading());
    }
    try {
      final customers = await adminRepository.getCustomers(page: event.page, search: event.searchQuery, status: event.status);
      
      if (state is AdminCustomersLoaded && event.page > 1) {
        final currentState = state as AdminCustomersLoaded;
        emit(AdminCustomersLoaded(
          customers: currentState.customers + customers,
          currentPage: event.page,
          hasReachedMax: customers.isEmpty || customers.length < 20,
        ));
      } else {
        emit(AdminCustomersLoaded(
          customers: customers,
          currentPage: event.page,
          hasReachedMax: customers.isEmpty || customers.length < 20,
        ));
      }
    } catch (e) {
      emit(AdminCustomersError(e.toString()));
    }
  }

  Future<void> _onBlockCustomer(BlockCustomer event, Emitter<AdminCustomersState> emit) async {
    try {
      await adminRepository.blockCustomer(event.customerId);
      _updateCustomerInState(event.customerId, 'blocked', emit);
    } catch (e) {
      // Re-emit error or handle it. For simplicity, just ignore or emit a specific error state
    }
  }

  Future<void> _onUnblockCustomer(UnblockCustomer event, Emitter<AdminCustomersState> emit) async {
    try {
      await adminRepository.unblockCustomer(event.customerId);
      _updateCustomerInState(event.customerId, 'active', emit);
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _onDeleteCustomer(DeleteCustomer event, Emitter<AdminCustomersState> emit) async {
    try {
      await adminRepository.deleteCustomer(event.customerId);
      if (state is AdminCustomersLoaded) {
        final currentState = state as AdminCustomersLoaded;
        final updatedCustomers = currentState.customers.where((c) => c.id != event.customerId).toList();
        emit(AdminCustomersLoaded(
          customers: updatedCustomers,
          currentPage: currentState.currentPage,
          hasReachedMax: currentState.hasReachedMax,
        ));
      }
    } catch (e) {
      // Handle error
    }
  }

  void _updateCustomerInState(String customerId, String newStatus, Emitter<AdminCustomersState> emit) {
    if (state is AdminCustomersLoaded) {
      final currentState = state as AdminCustomersLoaded;
      final updatedCustomers = currentState.customers.map((c) {
        if (c.id == customerId) {
          return c.copyWith(status: newStatus);
        }
        return c;
      }).toList();

      emit(AdminCustomersLoaded(
        customers: updatedCustomers,
        currentPage: currentState.currentPage,
        hasReachedMax: currentState.hasReachedMax,
      ));
    }
  }
}
