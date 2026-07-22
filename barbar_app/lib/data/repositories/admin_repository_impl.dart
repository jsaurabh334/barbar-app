import 'package:barbar_app/data/datasources/admin_remote_data_source.dart';
import 'package:barbar_app/data/models/barber_model.dart';
import 'package:barbar_app/data/models/dashboard_stats_model.dart';
import 'package:barbar_app/data/models/user_model.dart';
import 'package:barbar_app/data/models/vendor_model.dart';
import 'package:barbar_app/data/models/delivery_partner_model.dart';
import 'package:barbar_app/data/models/kyc_document_model.dart';
import 'package:barbar_app/data/models/admin_customer_details_model.dart';
import 'package:barbar_app/domain/repositories/admin_repository.dart';

class AdminRepositoryImpl implements AdminRepository {
  final AdminRemoteDataSource remoteDataSource;

  AdminRepositoryImpl(this.remoteDataSource);

  @override
  Future<DashboardStatsModel> getDashboardStats() {
    return remoteDataSource.getDashboardStats();
  }

  @override
  Future<List<BarberModel>> getBarbers({String? status, String? verificationStatus}) {
    return remoteDataSource.getBarbers(status: status, verificationStatus: verificationStatus);
  }

  @override
  Future<BarberModel> getBarberDetails(String id) {
    return remoteDataSource.getBarberDetails(id);
  }

  @override
  Future<void> approveBarber(String id) {
    return remoteDataSource.approveBarber(id);
  }

  @override
  Future<void> rejectBarber(String id, String reason) {
    return remoteDataSource.rejectBarber(id, reason);
  }

  @override
  Future<void> suspendBarber(String id) {
    return remoteDataSource.suspendBarber(id);
  }

  @override
  Future<void> activateBarber(String id) {
    return remoteDataSource.activateBarber(id);
  }

  @override
  Future<List<UserModel>> getCustomers({int page = 1, int limit = 20, String? search, String? status}) async {
    try {
      return await remoteDataSource.getCustomers(page: page, limit: limit, search: search, status: status);
    } catch (e) {
      if (page > 1) return [];
      return [
        UserModel(id: 'c1', phone: '+1234567890', fullName: 'Mock Customer 1', role: 'customer', status: 'active', otpVerified: true, languagePref: 'en'),
        UserModel(id: 'c2', phone: '+0987654321', fullName: 'Mock Customer 2', role: 'customer', status: 'blocked', otpVerified: true, languagePref: 'en'),
      ];
    }
  }

  @override
  Future<AdminCustomerDetailsModel> getCustomerDetails(String id) async {
    try {
      final data = await remoteDataSource.getCustomerDetails(id);
      return AdminCustomerDetailsModel.fromJson(data);
    } catch (e) {
      // Mock fallback
      return AdminCustomerDetailsModel(
        customer: UserModel(id: id, phone: '+1234567890', fullName: 'Mock Customer', role: 'customer', status: 'active', otpVerified: true, languagePref: 'en'),
        walletBalance: 500.0,
        transactions: [],
        bookings: [],
        reviews: [],
        totalBookings: 5,
        completedBookings: 4,
        cancelledBookings: 1,
        spent: 1200.0,
        rating: 4.5,
      );
    }
  }

  @override
  Future<void> blockCustomer(String id) async {
    return remoteDataSource.blockCustomer(id);
  }

  @override
  Future<void> unblockCustomer(String id) async {
    return remoteDataSource.unblockCustomer(id);
  }

  @override
  Future<void> deleteCustomer(String id) async {
    return remoteDataSource.deleteCustomer(id);
  }

  @override
  Future<List<VendorModel>> getVendors({int page = 1, int limit = 20, String? search}) async {
    try {
      final data = await remoteDataSource.getVendors(page: page, limit: limit, search: search);
      return data.map((json) => VendorModel.fromJson(json)).toList();
    } catch (e) {
      if (page > 1) return [];
      return [
        VendorModel(id: 'v1', userId: 'u1', businessName: 'Acme Products', status: 'pending', kycStatus: 'pending', rating: 0.0, totalRevenue: 0.0, city: 'Delhi'),
        VendorModel(id: 'v2', userId: 'u2', businessName: 'Hair Care Co', status: 'approved', kycStatus: 'verified', rating: 4.5, totalRevenue: 5000.0, city: 'Mumbai'),
      ];
    }
  }

  @override
  Future<void> approveVendor(String vendorId) async {
    return remoteDataSource.approveVendor(vendorId);
  }

  @override
  Future<void> rejectVendor(String vendorId, {String? remarks}) async {
    return remoteDataSource.rejectVendor(vendorId, remarks: remarks);
  }

  @override
  Future<void> suspendVendor(String vendorId) async {
    return remoteDataSource.suspendVendor(vendorId);
  }

  @override
  Future<void> reactivateVendor(String vendorId) async {
    return remoteDataSource.reactivateVendor(vendorId);
  }

  @override
  Future<List<dynamic>> getVendorDocuments(String vendorId) {
    return remoteDataSource.getVendorDocuments(vendorId);
  }

  @override
  Future<void> verifyVendorDocument(String documentId, String status, {String? remarks}) {
    return remoteDataSource.verifyVendorDocument(documentId, status, remarks: remarks);
  }

  @override
  Future<void> toggleVendorFeature({String? vendorId, bool isFeatured = false}) {
    return remoteDataSource.toggleVendorFeature(vendorId: vendorId, isFeatured: isFeatured);
  }

  @override
  Future<List<DeliveryPartnerModel>> getDeliveryPartners({int page = 1, int limit = 20, String? search, String? status}) async {
    try {
      final data = await remoteDataSource.getDeliveryPartners(page: page, limit: limit, search: search, status: status);
      return data.map((json) => DeliveryPartnerModel.fromJson(json)).toList();
    } catch (e) {
      if (page > 1) return [];
      return [
        DeliveryPartnerModel(
          id: 'd1', userId: 'u3', vehicleType: 'Bike', licenseNumber: 'DL123456', 
          currentLatitude: 0.0, currentLongitude: 0.0, availabilityStatus: 'available', rating: 4.8,
        ),
        DeliveryPartnerModel(
          id: 'd2', userId: 'u4', vehicleType: 'Scooter', licenseNumber: 'DL654321', 
          currentLatitude: 0.0, currentLongitude: 0.0, availabilityStatus: 'offline', rating: 4.2,
        ),
      ];
    }
  }

  @override
  Future<void> updateDeliveryPartnerStatus(String partnerId, String status) async {
    return remoteDataSource.updateDeliveryPartnerStatus(partnerId, status);
  }

  @override
  Future<void> updateDeliveryPartnerAvailability(String partnerId, String status) async {
    return remoteDataSource.updateDeliveryPartnerAvailability(partnerId, status);
  }

  @override
  Future<List<KycDocumentModel>> getKycDocuments(String userId) async {
    try {
      final data = await remoteDataSource.getKycDocuments(userId);
      return data.map((json) => KycDocumentModel.fromJson(json)).toList();
    } catch (e) {
      return [
        KycDocumentModel(id: 'k1', userId: userId, docType: 'PAN', docFrontUrl: 'https://placehold.co/600x400/png?text=PAN+Card', status: 'pending'),
        KycDocumentModel(id: 'k2', userId: userId, docType: 'Aadhaar Front', docFrontUrl: 'https://placehold.co/600x400/png?text=Aadhaar+Front', status: 'pending'),
        KycDocumentModel(id: 'k3', userId: userId, docType: 'Aadhaar Back', docFrontUrl: 'https://placehold.co/600x400/png?text=Aadhaar+Back', status: 'pending'),
        KycDocumentModel(id: 'k4', userId: userId, docType: 'Shop License', docFrontUrl: 'https://placehold.co/600x400/png?text=Shop+License', status: 'pending'),
      ];
    }
  }

  @override
  Future<void> approveKycDocument(String documentId) async {
    try {
      await remoteDataSource.approveKycDocument(documentId);
    } catch (_) {}
  }

  @override
  Future<void> rejectKycDocument(String documentId, String reason) async {
    try {
      await remoteDataSource.rejectKycDocument(documentId, reason);
    } catch (_) {}
  }

  @override
  Future<Map<String, dynamic>> getAllReviews({int page = 1, int limit = 20, String? status}) async {
    return remoteDataSource.getAllReviews(page: page, limit: limit, status: status);
  }

  @override
  Future<void> moderateReview(String reviewId, String status, {String reason = ''}) async {
    await remoteDataSource.moderateReview(reviewId, status, reason: reason);
  }

  @override
  Future<void> deleteReview(String reviewId) async {
    await remoteDataSource.deleteReview(reviewId);
  }

  @override
  Future<Map<String, dynamic>> getReviewAnalytics() async {
    return remoteDataSource.getReviewAnalytics();
  }

  @override
  Future<Map<String, dynamic>> getAllReports({int page = 1, int limit = 20, String? status}) async {
    return remoteDataSource.getAllReports(page: page, limit: limit, status: status);
  }

  @override
  Future<void> resolveReport(String reportId, String status) async {
    await remoteDataSource.resolveReport(reportId, status);
  }

  @override
  Future<Map<String, dynamic>> getDeliveryPresenceSummary() async {
    return await remoteDataSource.getDeliveryPresenceSummary();
  }

  @override
  Future<List<dynamic>> getOnlineDrivers() async {
    return await remoteDataSource.getOnlineDrivers();
  }

  @override
  Future<Map<String, dynamic>> getAdminBookings({int page = 1, int limit = 20, String? status, String? date, String? barberId}) {
    return remoteDataSource.getAdminBookings(page: page, limit: limit, status: status, date: date, barberId: barberId);
  }

  @override
  Future<Map<String, dynamic>> getAdminBookingDetail(String bookingId) {
    return remoteDataSource.getAdminBookingDetail(bookingId);
  }

  @override
  Future<void> adminCancelBooking(String bookingId, String reason) {
    return remoteDataSource.adminCancelBooking(bookingId, reason);
  }

  @override
  Future<void> adminRescheduleBooking(String bookingId, String newStart, String newEnd, {String? reason}) {
    return remoteDataSource.adminRescheduleBooking(bookingId, newStart, newEnd, reason: reason);
  }

  @override
  Future<List<dynamic>> getAdminBookingTimeline(String bookingId) {
    return remoteDataSource.getAdminBookingTimeline(bookingId);
  }

  @override
  Future<Map<String, dynamic>> getAdminOrders({int page = 1, int limit = 20, String? status, String? paymentStatus, String? vendorId, String? deliveryPartnerId, String? customerId, String? dateFrom, String? dateTo, String? search}) {
    return remoteDataSource.getAdminOrders(page: page, limit: limit, status: status, paymentStatus: paymentStatus, vendorId: vendorId, deliveryPartnerId: deliveryPartnerId, customerId: customerId, dateFrom: dateFrom, dateTo: dateTo, search: search);
  }

  @override
  Future<Map<String, dynamic>> getAdminOrderDetail(String orderId) {
    return remoteDataSource.getAdminOrderDetail(orderId);
  }

  @override
  Future<void> adminUpdateOrderStatus(String orderId, String status, {String? note}) {
    return remoteDataSource.adminUpdateOrderStatus(orderId, status, note: note);
  }

  @override
  Future<List<dynamic>> getAdminOrderTimeline(String orderId) {
    return remoteDataSource.getAdminOrderTimeline(orderId);
  }

  @override
  Future<void> adminAssignDriver(String orderId, String deliveryUserId) {
    return remoteDataSource.adminAssignDriver(orderId, deliveryUserId);
  }

  @override
  Future<Map<String, dynamic>> getAdminRefunds({int page = 1, int limit = 20, String? status}) {
    return remoteDataSource.getAdminRefunds(page: page, limit: limit, status: status);
  }

  @override
  Future<void> processAdminRefund(String refundId, String status, {double? amount, String? notes}) {
    return remoteDataSource.processAdminRefund(refundId, status, amount: amount, notes: notes);
  }

  @override
  Future<Map<String, dynamic>> getAdminRevenueAnalytics({String? period}) {
    return remoteDataSource.getAdminRevenueAnalytics(period: period);
  }

  @override
  Future<List<dynamic>> getAdminTaxSettings({String? type}) {
    return remoteDataSource.getAdminTaxSettings(type: type);
  }

  @override
  Future<Map<String, dynamic>> createAdminTaxSetting(Map<String, dynamic> data) {
    return remoteDataSource.createAdminTaxSetting(data);
  }

  @override
  Future<void> updateAdminTaxSetting(String id, Map<String, dynamic> data) {
    return remoteDataSource.updateAdminTaxSetting(id, data);
  }

  @override
  Future<void> deleteAdminTaxSetting(String id) {
    return remoteDataSource.deleteAdminTaxSetting(id);
  }

  @override
  Future<Map<String, dynamic>> getAdminDashboard() {
    return remoteDataSource.getAdminDashboard();
  }

  @override
  Future<void> updateAdminCommission(String vendorId, double rate) {
    return remoteDataSource.updateAdminCommission(vendorId, rate);
  }

  @override
  Future<Map<String, dynamic>> getAdminCoupons({int page = 1, int limit = 20, bool? isActive}) {
    return remoteDataSource.getAdminCoupons(page: page, limit: limit, isActive: isActive);
  }

  @override
  Future<Map<String, dynamic>> createAdminCoupon(Map<String, dynamic> data) {
    return remoteDataSource.createAdminCoupon(data);
  }

  @override
  Future<void> updateAdminCoupon(String id, Map<String, dynamic> data) {
    return remoteDataSource.updateAdminCoupon(id, data);
  }

  @override
  Future<void> deleteAdminCoupon(String id) {
    return remoteDataSource.deleteAdminCoupon(id);
  }

  @override
  Future<Map<String, dynamic>> getAdminFeaturedListings({int page = 1, int limit = 20, String? status}) {
    return remoteDataSource.getAdminFeaturedListings(page: page, limit: limit, status: status);
  }

  @override
  Future<Map<String, dynamic>> createAdminFeaturedListing(Map<String, dynamic> data) {
    return remoteDataSource.createAdminFeaturedListing(data);
  }

  @override
  Future<void> deleteAdminFeaturedListing(String id) {
    return remoteDataSource.deleteAdminFeaturedListing(id);
  }

  @override
  Future<Map<String, dynamic>> getAdminNotificationTemplates({int page = 1, int limit = 20, String? type, String? channel, bool? isActive}) {
    return remoteDataSource.getAdminNotificationTemplates(page: page, limit: limit, type: type, channel: channel, isActive: isActive);
  }

  @override
  Future<Map<String, dynamic>> getAdminNotificationTemplateDetail(String id) {
    return remoteDataSource.getAdminNotificationTemplateDetail(id);
  }

  @override
  Future<Map<String, dynamic>> createAdminNotificationTemplate(Map<String, dynamic> data) {
    return remoteDataSource.createAdminNotificationTemplate(data);
  }

  @override
  Future<void> updateAdminNotificationTemplate(String id, Map<String, dynamic> data) {
    return remoteDataSource.updateAdminNotificationTemplate(id, data);
  }

  @override
  Future<void> deleteAdminNotificationTemplate(String id) {
    return remoteDataSource.deleteAdminNotificationTemplate(id);
  }

  @override
  Future<Map<String, dynamic>> getAdminSettlements({int page = 1, int limit = 20, String? status, String? vendorId, String? dateFrom, String? dateTo, double? minAmount, double? maxAmount}) {
    return remoteDataSource.getAdminSettlements(page: page, limit: limit, status: status, vendorId: vendorId, dateFrom: dateFrom, dateTo: dateTo, minAmount: minAmount, maxAmount: maxAmount);
  }

  @override
  Future<Map<String, dynamic>> getAdminSettlementDetail(String id) {
    return remoteDataSource.getAdminSettlementDetail(id);
  }

  @override
  Future<void> processAdminSettlement(String id, String status, {String? adminNotes, String? utrNumber}) {
    return remoteDataSource.processAdminSettlement(id, status, adminNotes: adminNotes, utrNumber: utrNumber);
  }

  @override
  Future<Map<String, dynamic>> bulkProcessAdminSettlements(List<String> ids, String status, {String? utrNumber}) {
    return remoteDataSource.bulkProcessAdminSettlements(ids, status, utrNumber: utrNumber);
  }

  @override
  Future<Map<String, dynamic>> getAdminWallets({int page = 1, int limit = 20, String? type, bool? isActive}) {
    return remoteDataSource.getAdminWallets(page: page, limit: limit, type: type, isActive: isActive);
  }

  @override
  Future<Map<String, dynamic>> getAdminWalletDetail(String id) {
    return remoteDataSource.getAdminWalletDetail(id);
  }

  @override
  Future<void> creditAdminWallet(String id, double amount, {String? description}) {
    return remoteDataSource.creditAdminWallet(id, amount, description: description);
  }

  @override
  Future<void> debitAdminWallet(String id, double amount, {String? description}) {
    return remoteDataSource.debitAdminWallet(id, amount, description: description);
  }

  @override
  Future<void> toggleAdminWalletFreeze(String id) {
    return remoteDataSource.toggleAdminWalletFreeze(id);
  }

  @override
  Future<Map<String, dynamic>> getAdminCommissionTransactions({int page = 1, int limit = 20, String? vendorId, String? status, String? dateFrom, String? dateTo}) {
    return remoteDataSource.getAdminCommissionTransactions(page: page, limit: limit, vendorId: vendorId, status: status, dateFrom: dateFrom, dateTo: dateTo);
  }

  @override
  Future<Map<String, dynamic>> getAdminBookingAnalytics({String? period}) {
    return remoteDataSource.getAdminBookingAnalytics(period: period);
  }

  @override
  Future<Map<String, dynamic>> getAdminOrderAnalytics({String? period}) {
    return remoteDataSource.getAdminOrderAnalytics(period: period);
  }

  @override
  Future<Map<String, dynamic>> getAdminCustomerAnalytics({String? period}) {
    return remoteDataSource.getAdminCustomerAnalytics(period: period);
  }

  @override
  Future<Map<String, dynamic>> getAdminDeliveryAnalytics() {
    return remoteDataSource.getAdminDeliveryAnalytics();
  }

  @override
  Future<Map<String, dynamic>> getAdminBarberAnalytics() {
    return remoteDataSource.getAdminBarberAnalytics();
  }

  @override
  Future<Map<String, dynamic>> getAdminBanners({int page = 1, int limit = 20, String? position, bool? isActive}) {
    return remoteDataSource.getAdminBanners(page: page, limit: limit, position: position, isActive: isActive);
  }

  @override
  Future<Map<String, dynamic>> getAdminBannerDetail(String id) {
    return remoteDataSource.getAdminBannerDetail(id);
  }

  @override
  Future<Map<String, dynamic>> createAdminBanner(Map<String, dynamic> data) {
    return remoteDataSource.createAdminBanner(data);
  }

  @override
  Future<Map<String, dynamic>> updateAdminBanner(String id, Map<String, dynamic> data) {
    return remoteDataSource.updateAdminBanner(id, data);
  }

  @override
  Future<void> deleteAdminBanner(String id) {
    return remoteDataSource.deleteAdminBanner(id);
  }

  @override
  Future<void> toggleAdminBannerActive(String id) {
    return remoteDataSource.toggleAdminBannerActive(id);
  }

  @override
  Future<Map<String, dynamic>> getAdminCampaigns({int page = 1, int limit = 20, String? status, String? targetType}) {
    return remoteDataSource.getAdminCampaigns(page: page, limit: limit, status: status, targetType: targetType);
  }

  @override
  Future<Map<String, dynamic>> getAdminCampaignDetail(String id) {
    return remoteDataSource.getAdminCampaignDetail(id);
  }

  @override
  Future<Map<String, dynamic>> createAdminCampaign(Map<String, dynamic> data) {
    return remoteDataSource.createAdminCampaign(data);
  }

  @override
  Future<Map<String, dynamic>> updateAdminCampaign(String id, Map<String, dynamic> data) {
    return remoteDataSource.updateAdminCampaign(id, data);
  }

  @override
  Future<void> deleteAdminCampaign(String id) {
    return remoteDataSource.deleteAdminCampaign(id);
  }

  @override
  Future<void> sendAdminCampaign(String id) {
    return remoteDataSource.sendAdminCampaign(id);
  }

  @override
  Future<Map<String, dynamic>> getAdminCmsPages({int page = 1, int limit = 20, String? type, bool? isPublished}) {
    return remoteDataSource.getAdminCmsPages(page: page, limit: limit, type: type, isPublished: isPublished);
  }

  @override
  Future<Map<String, dynamic>> getAdminCmsPageDetail(String id) {
    return remoteDataSource.getAdminCmsPageDetail(id);
  }

  @override
  Future<Map<String, dynamic>> createAdminCmsPage(Map<String, dynamic> data) {
    return remoteDataSource.createAdminCmsPage(data);
  }

  @override
  Future<Map<String, dynamic>> updateAdminCmsPage(String id, Map<String, dynamic> data) {
    return remoteDataSource.updateAdminCmsPage(id, data);
  }

  @override
  Future<void> deleteAdminCmsPage(String id) {
    return remoteDataSource.deleteAdminCmsPage(id);
  }
}
