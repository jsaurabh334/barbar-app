import 'package:barbar_app/core/network/api_client.dart';
import 'package:barbar_app/data/models/barber_model.dart';
import 'package:barbar_app/data/models/dashboard_stats_model.dart';
import 'package:barbar_app/data/models/user_model.dart';

class AdminRemoteDataSource {
  final ApiClient apiClient;

  AdminRemoteDataSource(this.apiClient);

  Future<Map<String, dynamic>> getAdminOrders({int page = 1, int limit = 20, String? status, String? paymentStatus, String? vendorId, String? deliveryPartnerId, String? customerId, String? dateFrom, String? dateTo, String? search}) async {
    final queryParams = <String, dynamic>{'page': page, 'limit': limit};
    if (status != null && status.isNotEmpty) queryParams['status'] = status;
    if (paymentStatus != null && paymentStatus.isNotEmpty) queryParams['payment_status'] = paymentStatus;
    if (vendorId != null && vendorId.isNotEmpty) queryParams['vendor_id'] = vendorId;
    if (deliveryPartnerId != null && deliveryPartnerId.isNotEmpty) queryParams['delivery_partner_id'] = deliveryPartnerId;
    if (customerId != null && customerId.isNotEmpty) queryParams['customer_id'] = customerId;
    if (dateFrom != null && dateFrom.isNotEmpty) queryParams['date_from'] = dateFrom;
    if (dateTo != null && dateTo.isNotEmpty) queryParams['date_to'] = dateTo;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    final response = await apiClient.dio.get('/admin/orders', queryParameters: queryParams);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getAdminOrderDetail(String orderId) async {
    final response = await apiClient.dio.get('/admin/orders/$orderId');
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<void> adminUpdateOrderStatus(String orderId, String status, {String? note}) async {
    await apiClient.dio.put('/admin/orders/$orderId/status', data: {
      'status': status,
      if (note != null && note.isNotEmpty) 'note': note,
    });
  }

  Future<List<dynamic>> getAdminOrderTimeline(String orderId) async {
    final response = await apiClient.dio.get('/admin/orders/$orderId/timeline');
    return (response.data['data'] as List<dynamic>?) ?? [];
  }

  Future<void> adminAssignDriver(String orderId, String deliveryUserId) async {
    await apiClient.dio.post('/admin/orders/$orderId/assign-driver', data: {
      'delivery_user_id': deliveryUserId,
    });
  }

  Future<Map<String, dynamic>> getAdminRefunds({int page = 1, int limit = 20, String? status}) async {
    final queryParams = <String, dynamic>{'page': page, 'limit': limit};
    if (status != null && status.isNotEmpty) queryParams['status'] = status;
    final response = await apiClient.dio.get('/admin/refunds', queryParameters: queryParams);
    return response.data as Map<String, dynamic>;
  }

  Future<void> processAdminRefund(String refundId, String status, {double? amount, String? notes}) async {
    await apiClient.dio.put('/admin/refunds/$refundId/process', data: {
      'status': status,
      if (amount != null) 'amount': amount,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    });
  }

  Future<Map<String, dynamic>> getAdminRevenueAnalytics({String? period}) async {
    final queryParams = <String, dynamic>{};
    if (period != null && period.isNotEmpty) queryParams['period'] = period;
    final response = await apiClient.dio.get('/admin/analytics/revenue', queryParameters: queryParams);
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<List<dynamic>> getAdminTaxSettings({String? type}) async {
    final queryParams = <String, dynamic>{};
    if (type != null && type.isNotEmpty) queryParams['type'] = type;
    final response = await apiClient.dio.get('/admin/tax-settings', queryParameters: queryParams);
    return (response.data['data'] as List<dynamic>?) ?? [];
  }

  Future<Map<String, dynamic>> createAdminTaxSetting(Map<String, dynamic> data) async {
    final response = await apiClient.dio.post('/admin/tax-settings', data: data);
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<void> updateAdminTaxSetting(String id, Map<String, dynamic> data) async {
    await apiClient.dio.put('/admin/tax-settings/$id', data: data);
  }

  Future<void> deleteAdminTaxSetting(String id) async {
    await apiClient.dio.delete('/admin/tax-settings/$id');
  }

  Future<Map<String, dynamic>> getAdminDashboard() async {
    final response = await apiClient.dio.get('/admin/dashboard');
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<void> updateAdminCommission(String vendorId, double rate) async {
    await apiClient.dio.put('/admin/commission', data: {
      'vendor_id': vendorId,
      'rate': rate,
    });
  }

  Future<Map<String, dynamic>> getAdminBookings({int page = 1, int limit = 20, String? status, String? date, String? barberId}) async {
    final queryParams = <String, dynamic>{'page': page, 'limit': limit};
    if (status != null && status.isNotEmpty) queryParams['status'] = status;
    if (date != null && date.isNotEmpty) queryParams['date'] = date;
    if (barberId != null && barberId.isNotEmpty) queryParams['barber_id'] = barberId;
    final response = await apiClient.dio.get('/admin/bookings', queryParameters: queryParams);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getAdminBookingDetail(String bookingId) async {
    final response = await apiClient.dio.get('/admin/bookings/$bookingId');
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<void> adminCancelBooking(String bookingId, String reason) async {
    await apiClient.dio.put('/admin/bookings/$bookingId/cancel', data: {'reason': reason});
  }

  Future<void> adminRescheduleBooking(String bookingId, String newStart, String newEnd, {String? reason}) async {
    await apiClient.dio.put('/admin/bookings/$bookingId/reschedule', data: {
      'new_start': newStart,
      'new_end': newEnd,
      if (reason != null && reason.isNotEmpty) 'reason': reason,
    });
  }

  Future<List<dynamic>> getAdminBookingTimeline(String bookingId) async {
    final response = await apiClient.dio.get('/admin/bookings/$bookingId/timeline');
    return (response.data['data'] as List<dynamic>?) ?? [];
  }

  Future<DashboardStatsModel> getDashboardStats() async {
    final response = await apiClient.dio.get('/admin/dashboard');
    return DashboardStatsModel.fromJson(response.data['data']);
  }

  Future<List<BarberModel>> getBarbers({String? status, String? verificationStatus}) async {
    final queryParams = <String, dynamic>{};
    if (status != null) queryParams['status'] = status;
    if (verificationStatus != null) queryParams['verification_status'] = verificationStatus;

    final response = await apiClient.dio.get('/admin/barbers', queryParameters: queryParams);
    final data = response.data['data'] as List;
    return data.map((json) => BarberModel.fromJson(json)).toList();
  }

  Future<BarberModel> getBarberDetails(String id) async {
    final response = await apiClient.dio.get('/admin/barbers/$id');
    return BarberModel.fromJson(response.data['data']);
  }

  Future<void> approveBarber(String id) async {
    await apiClient.dio.put('/admin/barbers/$id/approve', data: {});
  }

  Future<void> rejectBarber(String id, String reason) async {
    await apiClient.dio.put('/admin/barbers/$id/reject', data: {'reason': reason});
  }

  Future<void> suspendBarber(String id) async {
    await apiClient.dio.put('/admin/barbers/$id/suspend', data: {});
  }

  Future<void> activateBarber(String id) async {
    await apiClient.dio.put('/admin/barbers/$id/activate', data: {});
  }

  Future<List<UserModel>> getCustomers({int page = 1, int limit = 20, String? search, String? status}) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (status != null && status.isNotEmpty) queryParams['status'] = status;

    final response = await apiClient.dio.get('/admin/customers', queryParameters: queryParams);
    
    final dynamic responseData = response.data['data'];
    final List dataList = responseData is List ? responseData : (responseData['data'] as List? ?? []);
    
    return dataList.map((json) => UserModel.fromJson(json)).toList();
  }

  Future<Map<String, dynamic>> getCustomerDetails(String customerId) async {
    final response = await apiClient.dio.get('/admin/customers/$customerId');
    return response.data['data'];
  }

  Future<void> blockCustomer(String customerId) async {
    await apiClient.dio.put('/admin/customers/$customerId/block');
  }

  Future<void> unblockCustomer(String customerId) async {
    await apiClient.dio.put('/admin/customers/$customerId/unblock');
  }

  Future<void> deleteCustomer(String customerId) async {
    await apiClient.dio.put('/admin/customers/$customerId/delete');
  }

  Future<List<dynamic>> getVendors({int page = 1, int limit = 20, String? search}) async {
    final queryParams = <String, dynamic>{'page': page, 'limit': limit};
    if (search != null && search.isNotEmpty) queryParams['search'] = search;

    final response = await apiClient.dio.get('/admin/vendors', queryParameters: queryParams);
    final dynamic responseData = response.data['data'];
    final List data = (responseData is Map && responseData.containsKey('vendors')) 
        ? responseData['vendors'] 
        : responseData;
    return data;
  }

  Future<void> approveVendor(String vendorId) async {
    await apiClient.dio.put('/admin/vendors/$vendorId/approve', data: {'status': 'approved'});
  }

  Future<void> rejectVendor(String vendorId, {String? remarks}) async {
    await apiClient.dio.put('/admin/vendors/$vendorId/approve', data: {
      'status': 'rejected',
      if (remarks != null && remarks.isNotEmpty) 'remarks': remarks,
    });
  }

  Future<void> suspendVendor(String vendorId) async {
    await apiClient.dio.put('/admin/vendors/$vendorId/approve', data: {'status': 'suspended'});
  }

  Future<void> reactivateVendor(String vendorId) async {
    await apiClient.dio.put('/admin/vendors/$vendorId/approve', data: {'status': 'approved'});
  }

  Future<List<dynamic>> getVendorDocuments(String vendorId) async {
    final response = await apiClient.dio.get('/admin/vendor-documents', queryParameters: {'vendor_id': vendorId});
    final dynamic data = response.data['data'];
    final List list = (data is Map && data.containsKey('documents')) ? data['documents'] : (data is List ? data : []);
    return list;
  }

  Future<void> verifyVendorDocument(String documentId, String status, {String? remarks}) async {
    await apiClient.dio.put('/admin/vendor-documents/$documentId/verify', data: {
      'status': status,
      if (remarks != null && remarks.isNotEmpty) 'remarks': remarks,
    });
  }

  Future<void> toggleVendorFeature({String? vendorId, bool isFeatured = false}) async {
    await apiClient.dio.put('/admin/features/toggle', data: {
      if (vendorId != null) 'vendor_id': vendorId,
      'is_featured': isFeatured,
    });
  }

  Future<Map<String, dynamic>> getAdminCoupons({int page = 1, int limit = 20, bool? isActive}) async {
    final queryParams = <String, dynamic>{'page': page, 'limit': limit};
    if (isActive != null) queryParams['is_active'] = isActive;
    final response = await apiClient.dio.get('/admin/coupons', queryParameters: queryParams);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createAdminCoupon(Map<String, dynamic> data) async {
    final response = await apiClient.dio.post('/admin/coupons', data: data);
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<void> updateAdminCoupon(String id, Map<String, dynamic> data) async {
    await apiClient.dio.put('/admin/coupons/$id', data: data);
  }

  Future<void> deleteAdminCoupon(String id) async {
    await apiClient.dio.delete('/admin/coupons/$id');
  }

  Future<Map<String, dynamic>> getAdminFeaturedListings({int page = 1, int limit = 20, String? status}) async {
    final queryParams = <String, dynamic>{'page': page, 'limit': limit};
    if (status != null && status.isNotEmpty) queryParams['status'] = status;
    final response = await apiClient.dio.get('/admin/featured-listings', queryParameters: queryParams);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createAdminFeaturedListing(Map<String, dynamic> data) async {
    final response = await apiClient.dio.post('/admin/featured-listings', data: data);
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<void> deleteAdminFeaturedListing(String id) async {
    await apiClient.dio.delete('/admin/featured-listings/$id');
  }

  Future<Map<String, dynamic>> getAdminNotificationTemplates({int page = 1, int limit = 20, String? type, String? channel, bool? isActive}) async {
    final queryParams = <String, dynamic>{'page': page, 'limit': limit};
    if (type != null && type.isNotEmpty) queryParams['type'] = type;
    if (channel != null && channel.isNotEmpty) queryParams['channel'] = channel;
    if (isActive != null) queryParams['is_active'] = isActive;
    final response = await apiClient.dio.get('/admin/notification-templates', queryParameters: queryParams);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getAdminNotificationTemplateDetail(String id) async {
    final response = await apiClient.dio.get('/admin/notification-templates/$id');
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createAdminNotificationTemplate(Map<String, dynamic> data) async {
    final response = await apiClient.dio.post('/admin/notification-templates', data: data);
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<void> updateAdminNotificationTemplate(String id, Map<String, dynamic> data) async {
    await apiClient.dio.put('/admin/notification-templates/$id', data: data);
  }

  Future<void> deleteAdminNotificationTemplate(String id) async {
    await apiClient.dio.delete('/admin/notification-templates/$id');
  }

  Future<List<dynamic>> getDeliveryPartners({int page = 1, int limit = 20, String? search, String? status}) async {
    final queryParams = <String, dynamic>{'page': page, 'limit': limit};
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (status != null && status.isNotEmpty) queryParams['status'] = status;
    final response = await apiClient.dio.get('/admin/delivery', queryParameters: queryParams);
    final dynamic data = response.data['data'];
    return (data is List) ? data : (data is Map && data.containsKey('partners') ? data['partners'] : []);
  }

  Future<void> updateDeliveryPartnerStatus(String partnerId, String status) async {
    await apiClient.dio.put('/admin/delivery/$partnerId/status', data: {'status': status});
  }

  Future<void> updateDeliveryPartnerAvailability(String partnerId, String status) async {
    await apiClient.dio.put('/admin/delivery/$partnerId/availability', data: {'availability_status': status});
  }

  Future<List<dynamic>> getKycDocuments(String userId) async {
    final response = await apiClient.dio.get('/admin/kyc-documents', queryParameters: {'user_id': userId});
    final dynamic data = response.data['data'];
    return (data is List) ? data : (data is Map && data.containsKey('documents') ? data['documents'] : []);
  }

  Future<void> approveKycDocument(String documentId) async {
    await apiClient.dio.put('/admin/kyc-documents/$documentId/approve');
  }

  Future<void> rejectKycDocument(String documentId, String reason) async {
    await apiClient.dio.put('/admin/kyc-documents/$documentId/reject', data: {'reason': reason});
  }

  Future<Map<String, dynamic>> getAllReviews({int page = 1, int limit = 20, String? status}) async {
    final queryParams = <String, dynamic>{'page': page, 'limit': limit};
    if (status != null && status.isNotEmpty) queryParams['status'] = status;
    final response = await apiClient.dio.get('/admin/reviews', queryParameters: queryParams);
    return response.data as Map<String, dynamic>;
  }

  Future<void> moderateReview(String reviewId, String status, {String reason = ''}) async {
    await apiClient.dio.put('/admin/reviews/$reviewId/moderate', data: {
      'status': status,
      if (reason.isNotEmpty) 'reason': reason,
    });
  }

  Future<void> deleteReview(String reviewId) async {
    await apiClient.dio.delete('/admin/reviews/$reviewId');
  }

  Future<Map<String, dynamic>> getReviewAnalytics() async {
    final response = await apiClient.dio.get('/admin/reviews/analytics');
    return response.data['data'] as Map<String, dynamic>? ?? {};
  }

  Future<Map<String, dynamic>> getAllReports({int page = 1, int limit = 20, String? status}) async {
    final queryParams = <String, dynamic>{'page': page, 'limit': limit};
    if (status != null && status.isNotEmpty) queryParams['status'] = status;
    final response = await apiClient.dio.get('/admin/reports', queryParameters: queryParams);
    return response.data as Map<String, dynamic>;
  }

  Future<void> resolveReport(String reportId, String status) async {
    await apiClient.dio.put('/admin/reports/$reportId/resolve', data: {'status': status});
  }

  Future<Map<String, dynamic>> getDeliveryPresenceSummary() async {
    final response = await apiClient.dio.get('/admin/delivery/presence-summary');
    return response.data['data'] as Map<String, dynamic>? ?? {};
  }

  Future<List<dynamic>> getOnlineDrivers() async {
    final response = await apiClient.dio.get('/admin/delivery/online-drivers');
    final dynamic data = response.data['data'];
    return (data is List) ? data : [];
  }

  Future<Map<String, dynamic>> getAdminSettlements({int page = 1, int limit = 20, String? status, String? vendorId, String? dateFrom, String? dateTo, double? minAmount, double? maxAmount}) async {
    final queryParams = <String, dynamic>{'page': page, 'limit': limit};
    if (status != null && status.isNotEmpty) queryParams['status'] = status;
    if (vendorId != null && vendorId.isNotEmpty) queryParams['vendor_id'] = vendorId;
    if (dateFrom != null && dateFrom.isNotEmpty) queryParams['date_from'] = dateFrom;
    if (dateTo != null && dateTo.isNotEmpty) queryParams['date_to'] = dateTo;
    if (minAmount != null) queryParams['min_amount'] = minAmount;
    if (maxAmount != null) queryParams['max_amount'] = maxAmount;
    final response = await apiClient.dio.get('/admin/settlements', queryParameters: queryParams);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getAdminSettlementDetail(String id) async {
    final response = await apiClient.dio.get('/admin/settlements/$id');
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<void> processAdminSettlement(String id, String status, {String? adminNotes, String? utrNumber}) async {
    await apiClient.dio.put('/admin/settlements/$id/process', data: {
      'status': status,
      if (adminNotes != null && adminNotes.isNotEmpty) 'admin_notes': adminNotes,
      if (utrNumber != null && utrNumber.isNotEmpty) 'utr_number': utrNumber,
    });
  }

  Future<Map<String, dynamic>> bulkProcessAdminSettlements(List<String> ids, String status, {String? utrNumber}) async {
    final response = await apiClient.dio.post('/admin/settlements/bulk-process', data: {
      'ids': ids,
      'status': status,
      if (utrNumber != null && utrNumber.isNotEmpty) 'utr_number': utrNumber,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getAdminWallets({int page = 1, int limit = 20, String? type, bool? isActive}) async {
    final queryParams = <String, dynamic>{'page': page, 'limit': limit};
    if (type != null && type.isNotEmpty) queryParams['type'] = type;
    if (isActive != null) queryParams['is_active'] = isActive;
    final response = await apiClient.dio.get('/admin/wallets', queryParameters: queryParams);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getAdminWalletDetail(String id) async {
    final response = await apiClient.dio.get('/admin/wallets/$id');
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<void> creditAdminWallet(String id, double amount, {String? description}) async {
    await apiClient.dio.post('/admin/wallets/$id/credit', data: {
      'amount': amount,
      if (description != null && description.isNotEmpty) 'description': description,
    });
  }

  Future<void> debitAdminWallet(String id, double amount, {String? description}) async {
    await apiClient.dio.post('/admin/wallets/$id/debit', data: {
      'amount': amount,
      if (description != null && description.isNotEmpty) 'description': description,
    });
  }

  Future<void> toggleAdminWalletFreeze(String id) async {
    await apiClient.dio.post('/admin/wallets/$id/toggle-freeze');
  }

  Future<Map<String, dynamic>> getAdminCommissionTransactions({int page = 1, int limit = 20, String? vendorId, String? status, String? dateFrom, String? dateTo}) async {
    final queryParams = <String, dynamic>{'page': page, 'limit': limit};
    if (vendorId != null && vendorId.isNotEmpty) queryParams['vendor_id'] = vendorId;
    if (status != null && status.isNotEmpty) queryParams['status'] = status;
    if (dateFrom != null && dateFrom.isNotEmpty) queryParams['date_from'] = dateFrom;
    if (dateTo != null && dateTo.isNotEmpty) queryParams['date_to'] = dateTo;
    final response = await apiClient.dio.get('/admin/commission-transactions', queryParameters: queryParams);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getAdminBookingAnalytics({String? period}) async {
    final response = await apiClient.dio.get('/admin/analytics/bookings', queryParameters: period != null ? {'period': period} : null);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getAdminOrderAnalytics({String? period}) async {
    final response = await apiClient.dio.get('/admin/analytics/orders', queryParameters: period != null ? {'period': period} : null);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getAdminCustomerAnalytics({String? period}) async {
    final response = await apiClient.dio.get('/admin/analytics/customers', queryParameters: period != null ? {'period': period} : null);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getAdminDeliveryAnalytics() async {
    final response = await apiClient.dio.get('/admin/analytics/delivery');
    return response.data['data'] as Map<String, dynamic>? ?? response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getAdminBarberAnalytics() async {
    final response = await apiClient.dio.get('/admin/analytics/barbers');
    return response.data['data'] as Map<String, dynamic>? ?? response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getAdminBanners({int page = 1, int limit = 20, String? position, bool? isActive}) async {
    final queryParams = <String, dynamic>{'page': page, 'limit': limit};
    if (position != null && position.isNotEmpty) queryParams['position'] = position;
    if (isActive != null) queryParams['is_active'] = isActive;
    final response = await apiClient.dio.get('/admin/banners', queryParameters: queryParams);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getAdminBannerDetail(String id) async {
    final response = await apiClient.dio.get('/admin/banners/$id');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createAdminBanner(Map<String, dynamic> data) async {
    final response = await apiClient.dio.post('/admin/banners', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateAdminBanner(String id, Map<String, dynamic> data) async {
    final response = await apiClient.dio.put('/admin/banners/$id', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<void> deleteAdminBanner(String id) async {
    await apiClient.dio.delete('/admin/banners/$id');
  }

  Future<void> toggleAdminBannerActive(String id) async {
    await apiClient.dio.put('/admin/banners/$id/toggle');
  }

  Future<Map<String, dynamic>> getAdminCampaigns({int page = 1, int limit = 20, String? status, String? targetType}) async {
    final queryParams = <String, dynamic>{'page': page, 'limit': limit};
    if (status != null && status.isNotEmpty) queryParams['status'] = status;
    if (targetType != null && targetType.isNotEmpty) queryParams['target_type'] = targetType;
    final response = await apiClient.dio.get('/admin/campaigns', queryParameters: queryParams);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getAdminCampaignDetail(String id) async {
    final response = await apiClient.dio.get('/admin/campaigns/$id');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createAdminCampaign(Map<String, dynamic> data) async {
    final response = await apiClient.dio.post('/admin/campaigns', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateAdminCampaign(String id, Map<String, dynamic> data) async {
    final response = await apiClient.dio.put('/admin/campaigns/$id', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<void> deleteAdminCampaign(String id) async {
    await apiClient.dio.delete('/admin/campaigns/$id');
  }

  Future<void> sendAdminCampaign(String id) async {
    await apiClient.dio.post('/admin/campaigns/$id/send');
  }

  Future<Map<String, dynamic>> getAdminCmsPages({int page = 1, int limit = 20, String? type, bool? isPublished}) async {
    final queryParams = <String, dynamic>{'page': page, 'limit': limit};
    if (type != null && type.isNotEmpty) queryParams['type'] = type;
    if (isPublished != null) queryParams['is_published'] = isPublished;
    final response = await apiClient.dio.get('/admin/cms', queryParameters: queryParams);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getAdminCmsPageDetail(String id) async {
    final response = await apiClient.dio.get('/admin/cms/$id');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createAdminCmsPage(Map<String, dynamic> data) async {
    final response = await apiClient.dio.post('/admin/cms', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateAdminCmsPage(String id, Map<String, dynamic> data) async {
    final response = await apiClient.dio.put('/admin/cms/$id', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<void> deleteAdminCmsPage(String id) async {
    await apiClient.dio.delete('/admin/cms/$id');
  }
}
