import 'package:equatable/equatable.dart';

abstract class AddressState extends Equatable {
  const AddressState();

  @override
  List<Object?> get props => [];
}

class AddressInitial extends AddressState {}

class AddressLoading extends AddressState {}

class AddressesLoaded extends AddressState {
  final List<Map<String, dynamic>> addresses;

  const AddressesLoaded(this.addresses);

  @override
  List<Object?> get props => [addresses];
}

class AddressOperationSuccess extends AddressState {
  final String message;

  const AddressOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class AddressFailure extends AddressState {
  final String error;

  const AddressFailure(this.error);

  @override
  List<Object?> get props => [error];
}
