import 'package:barbar_app/core/network/api_client.dart';
import 'package:barbar_app/data/models/barber_model.dart';
import 'package:barbar_app/data/models/dashboard_stats_model.dart';
import 'package:barbar_app/data/models/user_model.dart';

class AdminRemoteDataSource {
  final ApiClient apiClient;

  AdminRemoteDataSource(this.apiClient);

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
    await apiClient.dio.put('/admin/vendors/$vendorId/approve');
  }

  Future<void> suspendVendor(String vendorId) async {
    await apiClient.dio.put('/admin/vendors/$vendorId/suspend');
  }

  Future<List<dynamic>> getDeliveryPartners({int page = 1, int limit = 20, String? search}) async {
    final queryParams = <String, dynamic>{'page': page, 'limit': limit};
    if (search != null && search.isNotEmpty) queryParams['search'] = search;

    final response = await apiClient.dio.get('/admin/delivery', queryParameters: queryParams);
    final dynamic responseData = response.data['data'];
    final List data = (responseData is Map && responseData.containsKey('delivery_partners')) 
        ? responseData['delivery_partners'] 
        : responseData;
    return data;
  }

  Future<List<dynamic>> getKycDocuments(String userId) async {
    final response = await apiClient.dio.get('/admin/kyc', queryParameters: {'user_id': userId});
    final dynamic responseData = response.data['data'];
    final List data = (responseData is Map && responseData.containsKey('documents')) 
        ? responseData['documents'] 
        : responseData;
    return data;
  }

  Future<void> approveKycDocument(String documentId) async {
    await apiClient.dio.put('/admin/kyc/$documentId/approve');
  }

  Future<void> rejectKycDocument(String documentId, String reason) async {
    await apiClient.dio.put('/admin/kyc/$documentId/reject', data: {'reason': reason});
  }

  Future<void> updateDeliveryPartnerStatus(String partnerId, String status) async {
    await apiClient.dio.put('/admin/delivery/$partnerId/status', data: {'status': status});
  }

  Future<Map<String, dynamic>> getAllReviews({int page = 1, int limit = 20, String? status}) async {
    final queryParams = <String, dynamic>{'page': page, 'limit': limit};
    if (status != null) queryParams['status'] = status;
    final response = await apiClient.dio.get('/admin/reviews', queryParameters: queryParams);
    return response.data as Map<String, dynamic>;
  }

  Future<void> moderateReview(String reviewId, String status, {String reason = ''}) async {
    await apiClient.dio.put('/admin/reviews/$reviewId/moderate', data: {
      'status': status,
      if (reason.isNotEmpty) 'reason': reason,
    });
  }
}
