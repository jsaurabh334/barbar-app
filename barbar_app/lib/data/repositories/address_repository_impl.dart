import '../../domain/repositories/address_repository.dart';
import '../datasources/remote/address_remote_datasource.dart';

class AddressRepositoryImpl implements AddressRepository {
  final AddressRemoteDataSource _remoteDataSource;

  AddressRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<Map<String, dynamic>>> getAddresses() async {
    return await _remoteDataSource.getAddresses();
  }

  @override
  Future<Map<String, dynamic>> createAddress(Map<String, dynamic> address) async {
    return await _remoteDataSource.createAddress(address);
  }

  @override
  Future<Map<String, dynamic>> updateAddress(String id, Map<String, dynamic> address) async {
    return await _remoteDataSource.updateAddress(id, address);
  }

  @override
  Future<void> deleteAddress(String id) async {
    await _remoteDataSource.deleteAddress(id);
  }

  @override
  Future<void> setDefaultAddress(String id) async {
    await _remoteDataSource.setDefaultAddress(id);
  }
}
