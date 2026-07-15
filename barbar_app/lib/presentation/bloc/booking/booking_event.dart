import 'package:equatable/equatable.dart';

abstract class BookingEvent extends Equatable {
  const BookingEvent();

  @override
  List<Object?> get props => [];
}

class FetchServices extends BookingEvent {
  final String barberId;

  const FetchServices(this.barberId);

  @override
  List<Object?> get props => [barberId];
}

class CreateBooking extends BookingEvent {
  final String barberId;
  final List<String> serviceIds;
  final String scheduledStart;
  final String? staffId;
  final bool isHomeService;
  final String? homeServiceAddressId;

  const CreateBooking({
    required this.barberId,
    required this.serviceIds,
    required this.scheduledStart,
    this.staffId,
    this.isHomeService = false,
    this.homeServiceAddressId,
  });

  @override
  List<Object?> get props => [barberId, serviceIds, scheduledStart, staffId, isHomeService, homeServiceAddressId];
}

class CheckQueuePosition extends BookingEvent {
  final String bookingId;

  const CheckQueuePosition(this.bookingId);

  @override
  List<Object?> get props => [bookingId];
}

class CancelBooking extends BookingEvent {
  final String bookingId;
  final String? reason;

  const CancelBooking({required this.bookingId, this.reason});

  @override
  List<Object?> get props => [bookingId, reason];
}

class StreamQueuePositionUpdate extends BookingEvent {
  final int newPosition;
  final int estimatedWaitMin;
  final int remainingTime;
  final String currentlyServing;

  const StreamQueuePositionUpdate({
    required this.newPosition,
    required this.estimatedWaitMin,
    this.remainingTime = 0,
    this.currentlyServing = '',
  });

  @override
  List<Object?> get props => [newPosition, estimatedWaitMin, remainingTime, currentlyServing];
}

class UpdateBookingStatus extends BookingEvent {
  final String bookingId;
  final String status;

  const UpdateBookingStatus({required this.bookingId, required this.status});

  @override
  List<Object?> get props => [bookingId, status];
}

class FetchAllBookings extends BookingEvent {}

class FetchBarberBookings extends BookingEvent {}

class InitiateBookingPayment extends BookingEvent {
  final String bookingId;
  final String gateway;

  const InitiateBookingPayment({
    required this.bookingId,
    required this.gateway,
  });

  @override
  List<Object?> get props => [bookingId, gateway];
}

class VerifyBookingPayment extends BookingEvent {
  final String paymentId;
  final String gateway;
  final String razorpayOrderId;
  final String razorpayPaymentId;
  final String razorpaySignature;

  const VerifyBookingPayment({
    required this.paymentId,
    required this.gateway,
    required this.razorpayOrderId,
    required this.razorpayPaymentId,
    required this.razorpaySignature,
  });

  @override
  List<Object?> get props => [paymentId, gateway, razorpayOrderId, razorpayPaymentId, razorpaySignature];
}

class PayBooking extends BookingEvent {
  final String bookingId;
  final String method;
  final String status;
  final String reference;

  const PayBooking({
    required this.bookingId,
    required this.method,
    required this.status,
    required this.reference,
  });

  @override
  List<Object?> get props => [bookingId, method, status, reference];
}

class FetchAvailableSlots extends BookingEvent {
  final String barberId;
  final String date;

  const FetchAvailableSlots({required this.barberId, required this.date});

  @override
  List<Object?> get props => [barberId, date];
}

class FetchHomeServiceRequests extends BookingEvent {}

class AcceptHomeServiceRequest extends BookingEvent {
  final String bookingId;

  const AcceptHomeServiceRequest(this.bookingId);

  @override
  List<Object?> get props => [bookingId];
}

class RejectHomeServiceRequest extends BookingEvent {
  final String bookingId;
  final String reason;

  const RejectHomeServiceRequest({required this.bookingId, required this.reason});

  @override
  List<Object?> get props => [bookingId, reason];
}
