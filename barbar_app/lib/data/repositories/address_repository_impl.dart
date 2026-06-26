import '../../domain/repositories/address_repository.dart';
import '../datasources/remote/address_remote_datasource.dart';

class AddressRepositoryImpl implements AddressRepository {
  final AddressRemoteDataSource _remoteDataSource;

  AddressRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<Map<String, dynamic>>> getAddresses() async {
    try {
      return await _remoteDataSource.getAddresses();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<Map<String, dynamic>> createAddress(Map<String, dynamic> address) async {
    try {
      return await _remoteDataSource.createAddress(address);
    } catch (_) {
      throw Exception('Failed to create address');
    }
  }

  @override
  Future<Map<String, dynamic>> updateAddress(String id, Map<String, dynamic> address) async {
    try {
      return await _remoteDataSource.updateAddress(id, address);
    } catch (_) {
      throw Exception('Failed to update address');
    }
  }

  @override
  Future<void> deleteAddress(String id) async {
    try {
      await _remoteDataSource.deleteAddress(id);
    } catch (_) {
      throw Exception('Failed to delete address');
    }
  }

  @override
  Future<void> setDefaultAddress(String id) async {
    try {
      await _remoteDataSource.setDefaultAddress(id);
    } catch (_) {
      throw Exception('Failed to set default address');
    }
  }
}
