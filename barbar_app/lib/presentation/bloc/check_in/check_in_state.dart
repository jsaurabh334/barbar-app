import 'package:equatable/equatable.dart';
import '../../../data/models/booking_model.dart';

abstract class CheckInState extends Equatable {
  const CheckInState();

  @override
  List<Object?> get props => [];
}

class CheckInInitial extends CheckInState {}

class CheckInLoading extends CheckInState {}

class CheckInDataLoaded extends CheckInState {
  final BookingModel booking;

  const CheckInDataLoaded(this.booking);

  @override
  List<Object?> get props => [booking];
}

class CheckedInSuccess extends CheckInState {
  final BookingModel booking;

  const CheckedInSuccess(this.booking);

  @override
  List<Object?> get props => [booking];
}

class ImComingSuccess extends CheckInState {
  final BookingModel booking;

  const ImComingSuccess(this.booking);

  @override
  List<Object?> get props => [booking];
}

class CallPermissionLoaded extends CheckInState {
  final bool canCallShop;
  final bool canCallCustomer;
  final String? maskedShopPhone;
  final String? maskedCustomerPhone;

  const CallPermissionLoaded({
    required this.canCallShop,
    required this.canCallCustomer,
    this.maskedShopPhone,
    this.maskedCustomerPhone,
  });

  @override
  List<Object?> get props => [canCallShop, canCallCustomer, maskedShopPhone, maskedCustomerPhone];
}

class CheckInFailure extends CheckInState {
  final String error;

  const CheckInFailure(this.error);

  @override
  List<Object?> get props => [error];
}
