abstract class AddressRepository {
  Future<List<Map<String, dynamic>>> getAddresses();
  Future<Map<String, dynamic>> createAddress(Map<String, dynamic> address);
  Future<Map<String, dynamic>> updateAddress(String id, Map<String, dynamic> address);
  Future<void> deleteAddress(String id);
  Future<void> setDefaultAddress(String id);
}
