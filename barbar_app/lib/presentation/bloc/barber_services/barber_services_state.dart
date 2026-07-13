import 'package:equatable/equatable.dart';

abstract class BarberServicesState extends Equatable {
  const BarberServicesState();

  @override
  List<Object?> get props => [];
}

class BarberServicesInitial extends BarberServicesState {}

class BarberServicesLoading extends BarberServicesState {}

class BarberServicesLoaded extends BarberServicesState {
  final List<Map<String, dynamic>> services;

  const BarberServicesLoaded(this.services);

  @override
  List<Object?> get props => [services];
}

class BarberServicesSuccess extends BarberServicesState {
  final String message;

  const BarberServicesSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class BarberServicesFailure extends BarberServicesState {
  final String error;

  const BarberServicesFailure(this.error);

  @override
  List<Object?> get props => [error];
}
