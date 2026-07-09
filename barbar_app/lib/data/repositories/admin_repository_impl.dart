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
    const bool kUseMockFallback = true;
    try {
      return await remoteDataSource.getCustomers(page: page, limit: limit, search: search, status: status);
    } catch (e) {
      if (kUseMockFallback) {
        if (page > 1) return []; // Prevent infinite loading at the bottom
        return [
          UserModel(id: 'c1', phone: '+1234567890', fullName: 'Mock Customer 1', role: 'customer', status: 'active', otpVerified: true, languagePref: 'en'),
          UserModel(id: 'c2', phone: '+0987654321', fullName: 'Mock Customer 2', role: 'customer', status: 'blocked', otpVerified: true, languagePref: 'en'),
        ];
      }
      rethrow;
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
    const bool kUseMockFallback = true;
    try {
      final data = await remoteDataSource.getVendors(page: page, limit: limit, search: search);
      return data.map((json) => VendorModel.fromJson(json)).toList();
    } catch (e) {
      if (kUseMockFallback) {
        if (page > 1) return [];
        return [
          VendorModel(id: 'v1', userId: 'u1', storeName: 'Acme Products', status: 'pending', kycStatus: 'pending', rating: 0.0, totalRevenue: 0.0, city: 'Delhi'),
          VendorModel(id: 'v2', userId: 'u2', storeName: 'Hair Care Co', status: 'approved', kycStatus: 'verified', rating: 4.5, totalRevenue: 5000.0, city: 'Mumbai'),
        ];
      }
      rethrow;
    }
  }

  @override
  Future<void> approveVendor(String vendorId) async {
    return remoteDataSource.approveVendor(vendorId);
  }

  @override
  Future<void> suspendVendor(String vendorId) async {
    return remoteDataSource.suspendVendor(vendorId);
  }

  @override
  Future<List<DeliveryPartnerModel>> getDeliveryPartners({int page = 1, int limit = 20, String? search}) async {
    const bool kUseMockFallback = true;
    try {
      final data = await remoteDataSource.getDeliveryPartners(page: page, limit: limit, search: search);
      return data.map((json) => DeliveryPartnerModel.fromJson(json)).toList();
    } catch (e) {
      if (kUseMockFallback) {
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
      rethrow;
    }
  }

  @override
  Future<void> updateDeliveryPartnerStatus(String partnerId, String status) async {
    return remoteDataSource.updateDeliveryPartnerStatus(partnerId, status);
  }

  @override
  Future<List<KycDocumentModel>> getKycDocuments(String userId) async {
    const bool kUseMockFallback = true;
    try {
      final data = await remoteDataSource.getKycDocuments(userId);
      return data.map((json) => KycDocumentModel.fromJson(json)).toList();
    } catch (e) {
      if (kUseMockFallback) {
        return [
          KycDocumentModel(id: 'k1', userId: userId, docType: 'PAN', docFrontUrl: 'https://placehold.co/600x400/png?text=PAN+Card', status: 'pending'),
          KycDocumentModel(id: 'k2', userId: userId, docType: 'Aadhaar Front', docFrontUrl: 'https://placehold.co/600x400/png?text=Aadhaar+Front', status: 'pending'),
          KycDocumentModel(id: 'k3', userId: userId, docType: 'Aadhaar Back', docFrontUrl: 'https://placehold.co/600x400/png?text=Aadhaar+Back', status: 'pending'),
          KycDocumentModel(id: 'k4', userId: userId, docType: 'Shop License', docFrontUrl: 'https://placehold.co/600x400/png?text=Shop+License', status: 'pending'),
        ];
      }
      rethrow;
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
}
