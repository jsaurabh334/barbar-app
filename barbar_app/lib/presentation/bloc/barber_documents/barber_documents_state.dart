import 'package:equatable/equatable.dart';

abstract class BarberDocumentsState extends Equatable {
  const BarberDocumentsState();

  @override
  List<Object?> get props => [];
}

class BarberDocumentsInitial extends BarberDocumentsState {}

class BarberDocumentsLoading extends BarberDocumentsState {}

class BarberDocumentsLoaded extends BarberDocumentsState {
  final List<Map<String, dynamic>> documents;

  const BarberDocumentsLoaded(this.documents);

  @override
  List<Object?> get props => [documents];
}

class BarberDocumentsSuccess extends BarberDocumentsState {
  final String message;

  const BarberDocumentsSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class BarberDocumentsFailure extends BarberDocumentsState {
  final String error;

  const BarberDocumentsFailure(this.error);

  @override
  List<Object?> get props => [error];
}
