import 'package:equatable/equatable.dart';

abstract class AddressEvent extends Equatable {
  const AddressEvent();

  @override
  List<Object?> get props => [];
}

class FetchAddresses extends AddressEvent {}

class AddAddress extends AddressEvent {
  final Map<String, dynamic> address;

  const AddAddress(this.address);

  @override
  List<Object?> get props => [address];
}

class UpdateAddress extends AddressEvent {
  final String id;
  final Map<String, dynamic> address;

  const UpdateAddress({required this.id, required this.address});

  @override
  List<Object?> get props => [id, address];
}

class DeleteAddress extends AddressEvent {
  final String id;

  const DeleteAddress(this.id);

  @override
  List<Object?> get props => [id];
}

class SetDefaultAddress extends AddressEvent {
  final String id;

  const SetDefaultAddress(this.id);

  @override
  List<Object?> get props => [id];
}
