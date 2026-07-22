import 'package:barbar_app/data/models/barber_model.dart';
import 'package:barbar_app/data/models/dashboard_stats_model.dart';
import 'package:barbar_app/data/models/user_model.dart';
import 'package:barbar_app/data/models/vendor_model.dart';
import 'package:barbar_app/data/models/delivery_partner_model.dart';
import 'package:barbar_app/data/models/kyc_document_model.dart';
import 'package:barbar_app/data/models/admin_customer_details_model.dart';

abstract class AdminRepository {
  Future<DashboardStatsModel> getDashboardStats();
  Future<List<BarberModel>> getBarbers({String? status, String? verificationStatus});
  Future<BarberModel> getBarberDetails(String id);
  Future<void> approveBarber(String id);
  Future<void> rejectBarber(String id, String reason);
  Future<void> suspendBarber(String id);
  Future<void> activateBarber(String id);
  Future<List<UserModel>> getCustomers({int page = 1, int limit = 20, String? search, String? status});
  Future<AdminCustomerDetailsModel> getCustomerDetails(String id);
  Future<void> blockCustomer(String id);
  Future<void> unblockCustomer(String id);
  Future<void> deleteCustomer(String id);
  Future<List<VendorModel>> getVendors({int page = 1, int limit = 20, String? search});
  Future<void> approveVendor(String vendorId);
  Future<void> rejectVendor(String vendorId, {String? remarks});
  Future<void> suspendVendor(String vendorId);
  Future<void> reactivateVendor(String vendorId);
  Future<List<dynamic>> getVendorDocuments(String vendorId);
  Future<void> verifyVendorDocument(String documentId, String status, {String? remarks});
  Future<void> toggleVendorFeature({String? vendorId, bool isFeatured = false});

  Future<List<DeliveryPartnerModel>> getDeliveryPartners({int page = 1, int limit = 20, String? search, String? status});
  Future<void> updateDeliveryPartnerStatus(String partnerId, String status);
  Future<void> updateDeliveryPartnerAvailability(String partnerId, String status);

  Future<List<KycDocumentModel>> getKycDocuments(String userId);
  Future<void> approveKycDocument(String documentId);
  Future<void> rejectKycDocument(String documentId, String reason);

  Future<Map<String, dynamic>> getAllReviews({int page = 1, int limit = 20, String? status});
  Future<void> moderateReview(String reviewId, String status, {String reason = ''});
  Future<void> deleteReview(String reviewId);
  Future<Map<String, dynamic>> getReviewAnalytics();
  Future<Map<String, dynamic>> getAllReports({int page = 1, int limit = 20, String? status});
  Future<void> resolveReport(String reportId, String status);
  Future<Map<String, dynamic>> getDeliveryPresenceSummary();
  Future<List<dynamic>> getOnlineDrivers();

  Future<Map<String, dynamic>> getAdminBookings({int page = 1, int limit = 20, String? status, String? date, String? barberId});
  Future<Map<String, dynamic>> getAdminBookingDetail(String bookingId);
  Future<void> adminCancelBooking(String bookingId, String reason);
  Future<void> adminRescheduleBooking(String bookingId, String newStart, String newEnd, {String? reason});
  Future<List<dynamic>> getAdminBookingTimeline(String bookingId);

  Future<Map<String, dynamic>> getAdminOrders({int page = 1, int limit = 20, String? status, String? paymentStatus, String? vendorId, String? deliveryPartnerId, String? customerId, String? dateFrom, String? dateTo, String? search});
  Future<Map<String, dynamic>> getAdminOrderDetail(String orderId);
  Future<void> adminUpdateOrderStatus(String orderId, String status, {String? note});
  Future<List<dynamic>> getAdminOrderTimeline(String orderId);
  Future<void> adminAssignDriver(String orderId, String deliveryUserId);

  Future<Map<String, dynamic>> getAdminRefunds({int page = 1, int limit = 20, String? status});
  Future<void> processAdminRefund(String refundId, String status, {double? amount, String? notes});
  Future<Map<String, dynamic>> getAdminRevenueAnalytics({String? period});
  Future<List<dynamic>> getAdminTaxSettings({String? type});
  Future<Map<String, dynamic>> createAdminTaxSetting(Map<String, dynamic> data);
  Future<void> updateAdminTaxSetting(String id, Map<String, dynamic> data);
  Future<void> deleteAdminTaxSetting(String id);
  Future<Map<String, dynamic>> getAdminDashboard();
  Future<void> updateAdminCommission(String vendorId, double rate);

  Future<Map<String, dynamic>> getAdminCoupons({int page = 1, int limit = 20, bool? isActive});
  Future<Map<String, dynamic>> createAdminCoupon(Map<String, dynamic> data);
  Future<void> updateAdminCoupon(String id, Map<String, dynamic> data);
  Future<void> deleteAdminCoupon(String id);

  Future<Map<String, dynamic>> getAdminFeaturedListings({int page = 1, int limit = 20, String? status});
  Future<Map<String, dynamic>> createAdminFeaturedListing(Map<String, dynamic> data);
  Future<void> deleteAdminFeaturedListing(String id);

  Future<Map<String, dynamic>> getAdminNotificationTemplates({int page = 1, int limit = 20, String? type, String? channel, bool? isActive});
  Future<Map<String, dynamic>> getAdminNotificationTemplateDetail(String id);
  Future<Map<String, dynamic>> createAdminNotificationTemplate(Map<String, dynamic> data);
  Future<void> updateAdminNotificationTemplate(String id, Map<String, dynamic> data);
  Future<void> deleteAdminNotificationTemplate(String id);

  Future<Map<String, dynamic>> getAdminSettlements({int page = 1, int limit = 20, String? status, String? vendorId, String? dateFrom, String? dateTo, double? minAmount, double? maxAmount});
  Future<Map<String, dynamic>> getAdminSettlementDetail(String id);
  Future<void> processAdminSettlement(String id, String status, {String? adminNotes, String? utrNumber});
  Future<Map<String, dynamic>> bulkProcessAdminSettlements(List<String> ids, String status, {String? utrNumber});

  Future<Map<String, dynamic>> getAdminWallets({int page = 1, int limit = 20, String? type, bool? isActive});
  Future<Map<String, dynamic>> getAdminWalletDetail(String id);
  Future<void> creditAdminWallet(String id, double amount, {String? description});
  Future<void> debitAdminWallet(String id, double amount, {String? description});
  Future<void> toggleAdminWalletFreeze(String id);

  Future<Map<String, dynamic>> getAdminCommissionTransactions({int page = 1, int limit = 20, String? vendorId, String? status, String? dateFrom, String? dateTo});

  Future<Map<String, dynamic>> getAdminBookingAnalytics({String? period});
  Future<Map<String, dynamic>> getAdminOrderAnalytics({String? period});
  Future<Map<String, dynamic>> getAdminCustomerAnalytics({String? period});
  Future<Map<String, dynamic>> getAdminDeliveryAnalytics();
  Future<Map<String, dynamic>> getAdminBarberAnalytics();

  Future<Map<String, dynamic>> getAdminBanners({int page = 1, int limit = 20, String? position, bool? isActive});
  Future<Map<String, dynamic>> getAdminBannerDetail(String id);
  Future<Map<String, dynamic>> createAdminBanner(Map<String, dynamic> data);
  Future<Map<String, dynamic>> updateAdminBanner(String id, Map<String, dynamic> data);
  Future<void> deleteAdminBanner(String id);
  Future<void> toggleAdminBannerActive(String id);

  Future<Map<String, dynamic>> getAdminCampaigns({int page = 1, int limit = 20, String? status, String? targetType});
  Future<Map<String, dynamic>> getAdminCampaignDetail(String id);
  Future<Map<String, dynamic>> createAdminCampaign(Map<String, dynamic> data);
  Future<Map<String, dynamic>> updateAdminCampaign(String id, Map<String, dynamic> data);
  Future<void> deleteAdminCampaign(String id);
  Future<void> sendAdminCampaign(String id);

  Future<Map<String, dynamic>> getAdminCmsPages({int page = 1, int limit = 20, String? type, bool? isPublished});
  Future<Map<String, dynamic>> getAdminCmsPageDetail(String id);
  Future<Map<String, dynamic>> createAdminCmsPage(Map<String, dynamic> data);
  Future<Map<String, dynamic>> updateAdminCmsPage(String id, Map<String, dynamic> data);
  Future<void> deleteAdminCmsPage(String id);
}
