import '../../domain/repositories/delivery_repository.dart';
import '../datasources/remote/delivery_remote_datasource.dart';
import '../models/delivery_partner_model.dart';
import '../models/order_model.dart';

class DeliveryRepositoryImpl implements DeliveryRepository {
  final DeliveryRemoteDataSource _remoteDataSource;

  DeliveryRepositoryImpl(this._remoteDataSource);

  @override
  Future<DeliveryPartnerModel> register(Map<String, dynamic> data) async {
    final json = await _remoteDataSource.register(data);
    return DeliveryPartnerModel.fromJson(json);
  }

  @override
  Future<DeliveryPartnerModel> getProfile() async {
    final json = await _remoteDataSource.getProfile();
    return DeliveryPartnerModel.fromJson(json);
  }

  @override
  Future<List<OrderModel>> getAssignedOrders() async {
    final list = await _remoteDataSource.getAssignedOrders();
    return list.map((e) => OrderModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<OrderModel> getOrderById(String orderId) async {
    final json = await _remoteDataSource.getOrderById(orderId);
    return OrderModel.fromJson(json);
  }

  @override
  Future<void> claimOrder(String orderId) async {
    await _remoteDataSource.claimOrder(orderId);
  }

  @override
  Future<void> acceptAssignment(String orderId) async {
    await _remoteDataSource.acceptAssignment(orderId);
  }

  @override
  Future<void> rejectAssignment(String orderId) async {
    await _remoteDataSource.rejectAssignment(orderId);
  }

  @override
  Future<OrderModel> pickupOrder(String orderId) async {
    final json = await _remoteDataSource.pickupOrder(orderId);
    return OrderModel.fromJson(json);
  }

  @override
  Future<OrderModel> outForDelivery(String orderId) async {
    final json = await _remoteDataSource.outForDelivery(orderId);
    return OrderModel.fromJson(json);
  }

  @override
  Future<OrderModel> deliverOrder(String orderId) async {
    final json = await _remoteDataSource.deliverOrder(orderId);
    return OrderModel.fromJson(json);
  }

  @override
  Future<Map<String, dynamic>> goOnline({String? deviceId, String? appVersion}) async {
    return await _remoteDataSource.goOnline(deviceId: deviceId, appVersion: appVersion);
  }

  @override
  Future<void> goOffline() async {
    await _remoteDataSource.goOffline();
  }

  @override
  Future<void> heartbeat() async {
    await _remoteDataSource.heartbeat();
  }

  @override
  Future<Map<String, dynamic>> getMyPresence() async {
    return await _remoteDataSource.getMyPresence();
  }

  @override
  Future<Map<String, dynamic>> getOrderETA(String orderId) async {
    return await _remoteDataSource.getOrderETA(orderId);
  }

  @override
  Future<void> verifyOtp(String orderId, String otp, {String otpType = 'delivery'}) async {
    await _remoteDataSource.verifyOtp(orderId, otp, otpType: otpType);
  }

  @override
  Future<List<Map<String, dynamic>>> getEarnings({int limit = 20, int offset = 0}) async {
    return _remoteDataSource.getEarnings(limit: limit, offset: offset);
  }

  @override
  Future<Map<String, dynamic>> getEarningSummary() async {
    return _remoteDataSource.getEarningSummary();
  }

  @override
  Future<Map<String, dynamic>> getBankAccount() async {
    return _remoteDataSource.getBankAccount();
  }

  @override
  Future<Map<String, dynamic>> upsertBankAccount(Map<String, dynamic> data) async {
    return _remoteDataSource.upsertBankAccount(data);
  }

  @override
  Future<void> deleteBankAccount() async {
    return _remoteDataSource.deleteBankAccount();
  }

  @override
  Future<Map<String, dynamic>> sendLocation({
    required double latitude,
    required double longitude,
    double accuracy = 0,
    double speed = 0,
    double bearing = 0,
    String? timestamp,
  }) async {
    return await _remoteDataSource.sendLocation(
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
      speed: speed,
      bearing: bearing,
      timestamp: timestamp,
    );
  }
}
