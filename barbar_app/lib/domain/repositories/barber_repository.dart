abstract class BarberRepository {
  Future<Map<String, dynamic>> getDashboard();
  Future<void> updateProfile(Map<String, dynamic> data);
  Future<void> updateAvailability({required bool isAvailable, String? status});
  Future<Map<String, dynamic>> getEarnings({String period = 'week'});
  Future<List<Map<String, dynamic>>> getWeeklySchedule();
  Future<List<Map<String, dynamic>>> setWeeklySchedule(List<Map<String, dynamic>> schedule);
  Future<void> addHoliday({required String date, required String reason});
  Future<List<Map<String, dynamic>>> listHolidays();
  Future<List<Map<String, dynamic>>> getBarberServices();
  Future<Map<String, dynamic>> addService(Map<String, dynamic> data);
  Future<void> updateService(String serviceId, Map<String, dynamic> data);
  Future<void> deleteService(String serviceId);
  Future<List<Map<String, dynamic>>> getHomeServiceRequests();
  Future<void> acceptHomeService(String requestId);
  Future<void> rejectHomeService(String requestId);
  Future<void> uploadDocument(String docType, String docUrl);
  Future<List<Map<String, dynamic>>> listDocuments();
  Future<void> replaceDocument(String docId, String docType, String docUrl);
  Future<List<Map<String, dynamic>>> getStaff();
  Future<Map<String, dynamic>> addStaff(Map<String, dynamic> data);
  Future<Map<String, dynamic>> updateStaff(String staffId, Map<String, dynamic> data);
  Future<void> archiveStaff(String staffId);
  Future<List<String>> uploadShopImages(List<dynamic> files);
}
