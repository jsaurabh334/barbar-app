import '../../data/models/delivery_partner_model.dart';
import '../../data/models/order_model.dart';

abstract class DeliveryRepository {
  Future<DeliveryPartnerModel> register(Map<String, dynamic> data);
  Future<DeliveryPartnerModel> getProfile();
  Future<List<OrderModel>> getAssignedOrders();
  Future<OrderModel> getOrderById(String orderId);
  Future<void> claimOrder(String orderId);
  Future<void> acceptAssignment(String orderId);
  Future<void> rejectAssignment(String orderId);
  Future<OrderModel> pickupOrder(String orderId);
  Future<OrderModel> outForDelivery(String orderId);
  Future<OrderModel> deliverOrder(String orderId);
  Future<Map<String, dynamic>> goOnline({String? deviceId, String? appVersion});
  Future<void> goOffline();
  Future<void> heartbeat();
  Future<Map<String, dynamic>> getMyPresence();
  Future<Map<String, dynamic>> getOrderETA(String orderId);
  Future<void> verifyOtp(String orderId, String otp, {String otpType = 'delivery'});
  Future<List<Map<String, dynamic>>> getEarnings({int limit = 20, int offset = 0});
  Future<Map<String, dynamic>> getEarningSummary();
  Future<Map<String, dynamic>> getBankAccount();
  Future<Map<String, dynamic>> upsertBankAccount(Map<String, dynamic> data);
  Future<void> deleteBankAccount();
  Future<Map<String, dynamic>> sendLocation({
    required double latitude,
    required double longitude,
    double accuracy = 0,
    double speed = 0,
    double bearing = 0,
    String? timestamp,
  });
}
