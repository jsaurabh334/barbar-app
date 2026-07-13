import 'package:equatable/equatable.dart';

abstract class BarberProfileState extends Equatable {
  const BarberProfileState();

  @override
  List<Object?> get props => [];
}

class BarberProfileInitial extends BarberProfileState {}

class BarberProfileLoading extends BarberProfileState {}

class BarberProfileLoaded extends BarberProfileState {
  final Map<String, dynamic> profile;

  const BarberProfileLoaded(this.profile);

  @override
  List<Object?> get props => [profile];
}

class BarberProfileSuccess extends BarberProfileState {
  final String message;

  const BarberProfileSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class BarberProfileFailure extends BarberProfileState {
  final String error;

  const BarberProfileFailure(this.error);

  @override
  List<Object?> get props => [error];
}
