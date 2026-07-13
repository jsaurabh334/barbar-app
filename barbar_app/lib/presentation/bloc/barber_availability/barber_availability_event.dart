import 'package:equatable/equatable.dart';

abstract class BarberAvailabilityEvent extends Equatable {
  const BarberAvailabilityEvent();

  @override
  List<Object?> get props => [];
}

class FetchAvailability extends BarberAvailabilityEvent {}

class UpdateStatus extends BarberAvailabilityEvent {
  final String status;
  final bool isAvailable;

  const UpdateStatus({required this.status, required this.isAvailable});

  @override
  List<Object?> get props => [status, isAvailable];
}

class UpdateLocalScheduleEvent extends BarberAvailabilityEvent {
  final List<Map<String, dynamic>> schedule;

  const UpdateLocalScheduleEvent(this.schedule);

  @override
  List<Object?> get props => [schedule];
}

class SetWeeklySchedule extends BarberAvailabilityEvent {
  final List<Map<String, dynamic>> schedule;

  const SetWeeklySchedule(this.schedule);

  @override
  List<Object?> get props => [schedule];
}

class AddHoliday extends BarberAvailabilityEvent {
  final String date;
  final String reason;

  const AddHoliday({required this.date, required this.reason});

  @override
  List<Object?> get props => [date, reason];
}

class UpdateBreakTime extends BarberAvailabilityEvent {
  final String startTime;
  final String endTime;

  const UpdateBreakTime({required this.startTime, required this.endTime});

  @override
  List<Object?> get props => [startTime, endTime];
}
