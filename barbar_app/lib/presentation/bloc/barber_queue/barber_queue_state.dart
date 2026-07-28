import 'package:equatable/equatable.dart';
import '../../../data/models/booking_model.dart';

abstract class BarberQueueState extends Equatable {
  const BarberQueueState();

  @override
  List<Object?> get props => [];
}

class BarberQueueInitial extends BarberQueueState {}

class BarberQueueLoading extends BarberQueueState {}

class TodayQueueLoaded extends BarberQueueState {
  final List<BookingModel> serving;
  final List<BookingModel> next;
  final List<BookingModel> waiting;
  final List<BookingModel> late;
  final List<BookingModel> upcoming;
  final String? activeStaffId;
  final List<Map<String, dynamic>> availableStaff;
  final String shopName;
  final String shopAddress;

  const TodayQueueLoaded({
    this.serving = const [],
    this.next = const [],
    this.waiting = const [],
    this.late = const [],
    this.upcoming = const [],
    this.activeStaffId,
    this.availableStaff = const [],
    this.shopName = '',
    this.shopAddress = '',
  });

  @override
  List<Object?> get props => [serving, next, waiting, late, upcoming, activeStaffId, availableStaff, shopName, shopAddress];

  TodayQueueLoaded copyWith({
    List<BookingModel>? serving,
    List<BookingModel>? next,
    List<BookingModel>? waiting,
    List<BookingModel>? late,
    List<BookingModel>? upcoming,
    String? activeStaffId,
    List<Map<String, dynamic>>? availableStaff,
    String? shopName,
    String? shopAddress,
  }) {
    return TodayQueueLoaded(
      serving: serving ?? this.serving,
      next: next ?? this.next,
      waiting: waiting ?? this.waiting,
      late: late ?? this.late,
      upcoming: upcoming ?? this.upcoming,
      activeStaffId: activeStaffId ?? this.activeStaffId,
      availableStaff: availableStaff ?? this.availableStaff,
      shopName: shopName ?? this.shopName,
      shopAddress: shopAddress ?? this.shopAddress,
    );
  }
}

class BarberQueueActionSuccess extends BarberQueueState {
  final String message;

  const BarberQueueActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class BarberQueueFailure extends BarberQueueState {
  final String error;

  const BarberQueueFailure(this.error);

  @override
  List<Object?> get props => [error];
}
