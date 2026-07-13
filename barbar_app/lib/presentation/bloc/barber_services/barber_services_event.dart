import 'package:equatable/equatable.dart';

abstract class BarberServicesEvent extends Equatable {
  const BarberServicesEvent();

  @override
  List<Object?> get props => [];
}

class FetchServices extends BarberServicesEvent {}

class AddService extends BarberServicesEvent {
  final Map<String, dynamic> data;

  const AddService(this.data);

  @override
  List<Object?> get props => [data];
}

class UpdateService extends BarberServicesEvent {
  final String serviceId;
  final Map<String, dynamic> data;

  const UpdateService({required this.serviceId, required this.data});

  @override
  List<Object?> get props => [serviceId, data];
}

class DeleteService extends BarberServicesEvent {
  final String serviceId;

  const DeleteService(this.serviceId);

  @override
  List<Object?> get props => [serviceId];
}

class ToggleActive extends BarberServicesEvent {
  final String serviceId;
  final bool isActive;

  const ToggleActive({required this.serviceId, required this.isActive});

  @override
  List<Object?> get props => [serviceId, isActive];
}
