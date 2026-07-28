import 'package:equatable/equatable.dart';

abstract class BarberQueueEvent extends Equatable {
  const BarberQueueEvent();

  @override
  List<Object?> get props => [];
}

class LoadTodayQueue extends BarberQueueEvent {
  final String? staffId;

  const LoadTodayQueue({this.staffId});

  @override
  List<Object?> get props => [staffId];
}

class LoadTodayQueueRefresh extends BarberQueueEvent {
  final String? staffId;

  const LoadTodayQueueRefresh({this.staffId});

  @override
  List<Object?> get props => [staffId];
}

class FilterByStaff extends BarberQueueEvent {
  final String? staffId;

  const FilterByStaff(this.staffId);

  @override
  List<Object?> get props => [staffId];
}

class SkipCustomer extends BarberQueueEvent {
  final String bookingId;

  const SkipCustomer(this.bookingId);

  @override
  List<Object?> get props => [bookingId];
}

class StartService extends BarberQueueEvent {
  final String bookingId;

  const StartService(this.bookingId);

  @override
  List<Object?> get props => [bookingId];
}

class CompleteService extends BarberQueueEvent {
  final String bookingId;

  const CompleteService(this.bookingId);

  @override
  List<Object?> get props => [bookingId];
}

class MarkNoShow extends BarberQueueEvent {
  final String bookingId;

  const MarkNoShow(this.bookingId);

  @override
  List<Object?> get props => [bookingId];
}
