import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:barbar_app/domain/repositories/admin_repository.dart';

abstract class AdminOrdersEvent extends Equatable {
  const AdminOrdersEvent();
  @override
  List<Object?> get props => [];
}

class LoadOrders extends AdminOrdersEvent {
  final int page;
  final String? status;
  final String? paymentStatus;
  final String? search;

  const LoadOrders({this.page = 1, this.status, this.paymentStatus, this.search});
  @override
  List<Object?> get props => [page, status, paymentStatus, search];
}

class UpdateOrderStatus extends AdminOrdersEvent {
  final String orderId;
  final String status;
  final String? note;
  const UpdateOrderStatus(this.orderId, this.status, {this.note});
  @override
  List<Object?> get props => [orderId, status, note];
}

class AssignDriver extends AdminOrdersEvent {
  final String orderId;
  final String deliveryUserId;
  const AssignDriver(this.orderId, this.deliveryUserId);
  @override
  List<Object?> get props => [orderId, deliveryUserId];
}

abstract class AdminOrdersState extends Equatable {
  const AdminOrdersState();
  @override
  List<Object?> get props => [];
}

class AdminOrdersInitial extends AdminOrdersState {}

class AdminOrdersLoading extends AdminOrdersState {}

class AdminOrdersLoaded extends AdminOrdersState {
  final List<dynamic> orders;
  final int currentPage;
  final int totalCount;
  final bool hasReachedMax;

  const AdminOrdersLoaded({
    required this.orders, required this.currentPage, this.totalCount = 0, this.hasReachedMax = false,
  });
  @override
  List<Object?> get props => [orders, currentPage, totalCount, hasReachedMax];
}

class AdminOrdersError extends AdminOrdersState {
  final String message;
  const AdminOrdersError(this.message);
  @override
  List<Object?> get props => [message];
}

class AdminOrderDetailLoaded extends AdminOrdersState {
  final Map<String, dynamic> order;
  const AdminOrderDetailLoaded(this.order);
  @override
  List<Object?> get props => [order];
}

class AdminOrderActionSuccess extends AdminOrdersState {
  final String message;
  const AdminOrderActionSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

class AdminOrdersBloc extends Bloc<AdminOrdersEvent, AdminOrdersState> {
  final AdminRepository adminRepository;

  AdminOrdersBloc({required this.adminRepository}) : super(AdminOrdersInitial()) {
    on<LoadOrders>(_onLoadOrders);
    on<UpdateOrderStatus>(_onUpdateOrderStatus);
    on<AssignDriver>(_onAssignDriver);
  }

  Future<void> _onLoadOrders(LoadOrders event, Emitter<AdminOrdersState> emit) async {
    if (event.page == 1) emit(AdminOrdersLoading());
    try {
      final result = await adminRepository.getAdminOrders(
        page: event.page, status: event.status, paymentStatus: event.paymentStatus, search: event.search,
      );
      final List<dynamic> rawData = (result['data'] is List) ? result['data'] : (result['data']?['data'] ?? []);
      final int total = (result['total'] as num?)?.toInt() ?? rawData.length;
      if (state is AdminOrdersLoaded && event.page > 1) {
        final cur = state as AdminOrdersLoaded;
        emit(AdminOrdersLoaded(
          orders: cur.orders + rawData, currentPage: event.page, totalCount: total,
          hasReachedMax: rawData.isEmpty || cur.orders.length + rawData.length >= total,
        ));
      } else {
        emit(AdminOrdersLoaded(
          orders: rawData, currentPage: event.page, totalCount: total,
          hasReachedMax: rawData.isEmpty || rawData.length >= total,
        ));
      }
    } catch (e) {
      emit(AdminOrdersError(e.toString()));
    }
  }

  Future<void> _onUpdateOrderStatus(UpdateOrderStatus event, Emitter<AdminOrdersState> emit) async {
    try {
      await adminRepository.adminUpdateOrderStatus(event.orderId, event.status, note: event.note);
      emit(AdminOrderActionSuccess('Order status updated to $event.status'));
    } catch (e) {
      emit(AdminOrdersError(e.toString()));
    }
  }

  Future<void> _onAssignDriver(AssignDriver event, Emitter<AdminOrdersState> emit) async {
    try {
      await adminRepository.adminAssignDriver(event.orderId, event.deliveryUserId);
      emit(AdminOrderActionSuccess('Driver assigned'));
    } catch (e) {
      emit(AdminOrdersError(e.toString()));
    }
  }
}
