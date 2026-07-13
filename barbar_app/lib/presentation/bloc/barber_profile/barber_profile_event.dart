import 'package:equatable/equatable.dart';

abstract class BarberProfileEvent extends Equatable {
  const BarberProfileEvent();

  @override
  List<Object?> get props => [];
}

class FetchBarberProfile extends BarberProfileEvent {}

class UpdateBarberProfile extends BarberProfileEvent {
  final Map<String, dynamic> data;

  const UpdateBarberProfile(this.data);

  @override
  List<Object?> get props => [data];
}
