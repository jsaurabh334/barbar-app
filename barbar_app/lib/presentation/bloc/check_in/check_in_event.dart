import 'package:equatable/equatable.dart';

abstract class CheckInEvent extends Equatable {
  const CheckInEvent();

  @override
  List<Object?> get props => [];
}

class LoadCheckInData extends CheckInEvent {
  final String bookingId;

  const LoadCheckInData(this.bookingId);

  @override
  List<Object?> get props => [bookingId];
}

class CheckInWithQr extends CheckInEvent {
  final String bookingId;
  final String token;

  const CheckInWithQr({required this.bookingId, required this.token});

  @override
  List<Object?> get props => [bookingId, token];
}

class CheckInManual extends CheckInEvent {
  final String bookingId;
  final double? lat;
  final double? lng;

  const CheckInManual({required this.bookingId, this.lat, this.lng});

  @override
  List<Object?> get props => [bookingId, lat, lng];
}

class ImComing extends CheckInEvent {
  final String bookingId;

  const ImComing(this.bookingId);

  @override
  List<Object?> get props => [bookingId];
}

class GetCallPermission extends CheckInEvent {
  final String bookingId;

  const GetCallPermission(this.bookingId);

  @override
  List<Object?> get props => [bookingId];
}

class ResetCheckIn extends CheckInEvent {}
