import 'package:equatable/equatable.dart';

abstract class BarberAvailabilityState extends Equatable {
  const BarberAvailabilityState();

  @override
  List<Object?> get props => [];
}

class BarberAvailabilityInitial extends BarberAvailabilityState {}

class BarberAvailabilityLoading extends BarberAvailabilityState {}

class BarberAvailabilityLoaded extends BarberAvailabilityState {
  final String currentStatus;
  final bool isAvailable;
  final List<Map<String, dynamic>> weeklySchedule;
  final List<Map<String, dynamic>> holidays;
  final String? breakStartTime;
  final String? breakEndTime;

  const BarberAvailabilityLoaded({
    required this.currentStatus,
    required this.isAvailable,
    required this.weeklySchedule,
    required this.holidays,
    this.breakStartTime,
    this.breakEndTime,
  });

  @override
  List<Object?> get props => [currentStatus, isAvailable, weeklySchedule, holidays, breakStartTime, breakEndTime];
}

class BarberAvailabilitySuccess extends BarberAvailabilityState {
  final String message;

  const BarberAvailabilitySuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class BarberAvailabilityFailure extends BarberAvailabilityState {
  final String error;

  const BarberAvailabilityFailure(this.error);

  @override
  List<Object?> get props => [error];
}
