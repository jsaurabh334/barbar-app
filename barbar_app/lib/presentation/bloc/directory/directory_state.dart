import 'package:equatable/equatable.dart';
import '../../../data/models/barber_model.dart';

abstract class DirectoryState extends Equatable {
  const DirectoryState();

  @override
  List<Object?> get props => [];
}

class DirectoryInitial extends DirectoryState {}

class DirectoryLoading extends DirectoryState {}

class DirectoryLoaded extends DirectoryState {
  final List<BarberModel> barbers;

  const DirectoryLoaded(this.barbers);

  @override
  List<Object?> get props => [barbers];
}

class DirectoryFailure extends DirectoryState {
  final String error;

  const DirectoryFailure(this.error);

  @override
  List<Object?> get props => [error];
}
