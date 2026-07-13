import 'dart:io';
import '../../domain/repositories/barber_repository.dart';
import '../datasources/remote/barber_remote_datasource.dart';

class BarberRepositoryImpl implements BarberRepository {
  final BarberRemoteDataSource _remoteDataSource;

  BarberRepositoryImpl(this._remoteDataSource);

  @override
  Future<Map<String, dynamic>> getDashboard() async {
    return await _remoteDataSource.getDashboard();
  }

  @override
  Future<void> updateProfile(Map<String, dynamic> data) async {
    await _remoteDataSource.updateProfile(data);
  }

  @override
  Future<void> updateAvailability({required bool isAvailable, String? status}) async {
    await _remoteDataSource.updateAvailability(isAvailable: isAvailable, status: status);
  }

  @override
  Future<Map<String, dynamic>> getEarnings({String period = 'week'}) async {
    return await _remoteDataSource.getEarnings(period: period);
  }

  @override
  Future<List<Map<String, dynamic>>> getWeeklySchedule() async {
    return await _remoteDataSource.getWeeklySchedule();
  }

  @override
  Future<List<Map<String, dynamic>>> setWeeklySchedule(List<Map<String, dynamic>> schedule) async {
    return await _remoteDataSource.setWeeklySchedule(schedule);
  }

  @override
  Future<void> addHoliday({required String date, required String reason}) async {
    await _remoteDataSource.addHoliday(date: date, reason: reason);
  }

  @override
  Future<List<Map<String, dynamic>>> listHolidays() async {
    return await _remoteDataSource.listHolidays();
  }

  @override
  Future<List<Map<String, dynamic>>> getBarberServices() async {
    return await _remoteDataSource.getBarberServices();
  }

  @override
  Future<Map<String, dynamic>> addService(Map<String, dynamic> data) async {
    return await _remoteDataSource.addService(data);
  }

  @override
  Future<void> updateService(String serviceId, Map<String, dynamic> data) async {
    await _remoteDataSource.updateService(serviceId, data);
  }

  @override
  Future<void> deleteService(String serviceId) async {
    await _remoteDataSource.deleteService(serviceId);
  }

  @override
  Future<List<Map<String, dynamic>>> getHomeServiceRequests() async {
    return await _remoteDataSource.getHomeServiceRequests();
  }

  @override
  Future<void> acceptHomeService(String requestId) async {
    await _remoteDataSource.acceptHomeService(requestId);
  }

  @override
  Future<void> rejectHomeService(String requestId) async {
    await _remoteDataSource.rejectHomeService(requestId);
  }

  @override
  Future<void> uploadDocument(String docType, String docUrl) async {
    await _remoteDataSource.uploadDocument(docType, docUrl);
  }

  @override
  Future<List<Map<String, dynamic>>> listDocuments() async {
    return await _remoteDataSource.listDocuments();
  }

  @override
  Future<void> replaceDocument(String docId, String docType, String docUrl) async {
    await _remoteDataSource.replaceDocument(docId, docType, docUrl);
  }

  @override
  Future<List<Map<String, dynamic>>> getStaff() async {
    return await _remoteDataSource.getStaff();
  }

  @override
  Future<Map<String, dynamic>> addStaff(Map<String, dynamic> data) async {
    return await _remoteDataSource.addStaff(data);
  }

  @override
  Future<Map<String, dynamic>> updateStaff(String staffId, Map<String, dynamic> data) async {
    return await _remoteDataSource.updateStaff(staffId, data);
  }

  @override
  Future<void> archiveStaff(String staffId) async {
    await _remoteDataSource.archiveStaff(staffId);
  }

  @override
  Future<List<String>> uploadShopImages(List<dynamic> files) async {
    return await _remoteDataSource.uploadShopImages(
      files.map((f) => f as File).toList(),
    );
  }
}
