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
  Future<void> suspendVendor(String vendorId);

  Future<List<DeliveryPartnerModel>> getDeliveryPartners({int page = 1, int limit = 20, String? search});
  Future<void> updateDeliveryPartnerStatus(String partnerId, String status);

  Future<List<KycDocumentModel>> getKycDocuments(String userId);
  Future<void> approveKycDocument(String documentId);
  Future<void> rejectKycDocument(String documentId, String reason);
}
