import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/address_repository.dart';
import 'address_event.dart';
import 'address_state.dart';

class AddressBloc extends Bloc<AddressEvent, AddressState> {
  final AddressRepository _addressRepository;

  AddressBloc(this._addressRepository) : super(AddressInitial()) {
    on<FetchAddresses>(_onFetchAddresses);
    on<AddAddress>(_onAddAddress);
    on<UpdateAddress>(_onUpdateAddress);
    on<DeleteAddress>(_onDeleteAddress);
    on<SetDefaultAddress>(_onSetDefaultAddress);
  }

  Future<void> _onFetchAddresses(FetchAddresses event, Emitter<AddressState> emit) async {
    emit(AddressLoading());
    try {
      final addresses = await _addressRepository.getAddresses();
      emit(AddressesLoaded(addresses));
    } catch (e) {
      emit(AddressFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onAddAddress(AddAddress event, Emitter<AddressState> emit) async {
    emit(AddressLoading());
    try {
      await _addressRepository.createAddress(event.address);
      final addresses = await _addressRepository.getAddresses();
      emit(AddressesLoaded(addresses));
    } catch (e) {
      emit(AddressFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onUpdateAddress(UpdateAddress event, Emitter<AddressState> emit) async {
    emit(AddressLoading());
    try {
      await _addressRepository.updateAddress(event.id, event.address);
      final addresses = await _addressRepository.getAddresses();
      emit(AddressesLoaded(addresses));
    } catch (e) {
      emit(AddressFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onDeleteAddress(DeleteAddress event, Emitter<AddressState> emit) async {
    emit(AddressLoading());
    try {
      await _addressRepository.deleteAddress(event.id);
      final addresses = await _addressRepository.getAddresses();
      emit(AddressesLoaded(addresses));
    } catch (e) {
      emit(AddressFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onSetDefaultAddress(SetDefaultAddress event, Emitter<AddressState> emit) async {
    emit(AddressLoading());
    try {
      await _addressRepository.setDefaultAddress(event.id);
      final addresses = await _addressRepository.getAddresses();
      emit(AddressesLoaded(addresses));
    } catch (e) {
      emit(AddressFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
