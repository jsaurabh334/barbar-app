import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:barbar_app/domain/repositories/admin_repository.dart';

// --- Events ---
abstract class AdminBookingsEvent extends Equatable {
  const AdminBookingsEvent();
  @override
  List<Object?> get props => [];
}

class LoadBookings extends AdminBookingsEvent {
  final int page;
  final String? status;
  final String? date;
  final String? barberId;

  const LoadBookings({this.page = 1, this.status, this.date, this.barberId});

  @override
  List<Object?> get props => [page, status, date, barberId];
}

class CancelBooking extends AdminBookingsEvent {
  final String bookingId;
  final String reason;
  const CancelBooking(this.bookingId, this.reason);

  @override
  List<Object?> get props => [bookingId, reason];
}

class RescheduleBooking extends AdminBookingsEvent {
  final String bookingId;
  final String newStart;
  final String newEnd;
  final String? reason;
  const RescheduleBooking({required this.bookingId, required this.newStart, required this.newEnd, this.reason});

  @override
  List<Object?> get props => [bookingId, newStart, newEnd, reason];
}

// --- States ---
abstract class AdminBookingsState extends Equatable {
  const AdminBookingsState();
  @override
  List<Object?> get props => [];
}

class AdminBookingsInitial extends AdminBookingsState {}

class AdminBookingsLoading extends AdminBookingsState {}

class AdminBookingsLoaded extends AdminBookingsState {
  final List<dynamic> bookings;
  final int currentPage;
  final int totalCount;
  final bool hasReachedMax;

  const AdminBookingsLoaded({
    required this.bookings,
    required this.currentPage,
    this.totalCount = 0,
    this.hasReachedMax = false,
  });

  @override
  List<Object?> get props => [bookings, currentPage, totalCount, hasReachedMax];
}

class AdminBookingsError extends AdminBookingsState {
  final String message;
  const AdminBookingsError(this.message);

  @override
  List<Object?> get props => [message];
}

class AdminBookingDetailLoaded extends AdminBookingsState {
  final Map<String, dynamic> booking;

  const AdminBookingDetailLoaded(this.booking);

  @override
  List<Object?> get props => [booking];
}

class AdminBookingActionSuccess extends AdminBookingsState {
  final String message;
  const AdminBookingActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

// --- Bloc ---
class AdminBookingsBloc extends Bloc<AdminBookingsEvent, AdminBookingsState> {
  final AdminRepository adminRepository;

  AdminBookingsBloc({required this.adminRepository}) : super(AdminBookingsInitial()) {
    on<LoadBookings>(_onLoadBookings);
    on<CancelBooking>(_onCancelBooking);
    on<RescheduleBooking>(_onRescheduleBooking);
  }

  Future<void> _onLoadBookings(LoadBookings event, Emitter<AdminBookingsState> emit) async {
    if (event.page == 1) {
      emit(AdminBookingsLoading());
    }
    try {
      final result = await adminRepository.getAdminBookings(
        page: event.page,
        status: event.status,
        date: event.date,
        barberId: event.barberId,
      );

      final List<dynamic> rawData = (result['data'] is List) ? result['data'] : (result['data']?['data'] ?? []);
      final int total = (result['total'] as num?)?.toInt() ?? rawData.length;

      if (state is AdminBookingsLoaded && event.page > 1) {
        final currentState = state as AdminBookingsLoaded;
        emit(AdminBookingsLoaded(
          bookings: currentState.bookings + rawData,
          currentPage: event.page,
          totalCount: total,
          hasReachedMax: rawData.isEmpty || currentState.bookings.length + rawData.length >= total,
        ));
      } else {
        emit(AdminBookingsLoaded(
          bookings: rawData,
          currentPage: event.page,
          totalCount: total,
          hasReachedMax: rawData.isEmpty || rawData.length >= total,
        ));
      }
    } catch (e) {
      emit(AdminBookingsError(e.toString()));
    }
  }

  Future<void> _onCancelBooking(CancelBooking event, Emitter<AdminBookingsState> emit) async {
    try {
      await adminRepository.adminCancelBooking(event.bookingId, event.reason);
      emit(AdminBookingActionSuccess('Booking cancelled successfully'));
    } catch (e) {
      emit(AdminBookingsError(e.toString()));
    }
  }

  Future<void> _onRescheduleBooking(RescheduleBooking event, Emitter<AdminBookingsState> emit) async {
    try {
      await adminRepository.adminRescheduleBooking(
        event.bookingId, event.newStart, event.newEnd,
        reason: event.reason,
      );
      emit(AdminBookingActionSuccess('Booking rescheduled successfully'));
    } catch (e) {
      emit(AdminBookingsError(e.toString()));
    }
  }
}
