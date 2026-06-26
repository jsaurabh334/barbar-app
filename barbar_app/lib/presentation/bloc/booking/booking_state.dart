import 'package:equatable/equatable.dart';
import '../../../data/models/booking_model.dart';
import '../../../data/models/service_model.dart';

abstract class BookingState extends Equatable {
  const BookingState();

  @override
  List<Object?> get props => [];
}

class BookingInitial extends BookingState {}

class BookingLoading extends BookingState {}

class ServicesLoaded extends BookingState {
  final List<ServiceModel> services;

  const ServicesLoaded(this.services);

  @override
  List<Object?> get props => [services];
}

class BookingCreatedSuccess extends BookingState {
  final BookingModel booking;

  const BookingCreatedSuccess(this.booking);

  @override
  List<Object?> get props => [booking];
}

class QueuePositionLoaded extends BookingState {
  final int currentPosition;
  final int peopleAhead;
  final int estimatedWaitMin;

  const QueuePositionLoaded({
    required this.currentPosition,
    required this.peopleAhead,
    required this.estimatedWaitMin,
  });

  @override
  List<Object?> get props => [currentPosition, peopleAhead, estimatedWaitMin];
}

class BookingsLoaded extends BookingState {
  final List<BookingModel> bookings;

  const BookingsLoaded(this.bookings);

  @override
  List<Object?> get props => [bookings];
}

class BookingFailure extends BookingState {
  final String error;

  const BookingFailure(this.error);

  @override
  List<Object?> get props => [error];
}
