import '../../domain/repositories/booking_repository.dart';
import '../datasources/remote/booking_remote_datasource.dart';
import '../models/booking_model.dart';
import '../models/service_model.dart';

class BookingRepositoryImpl implements BookingRepository {
  final BookingRemoteDataSource _remoteDataSource;

  BookingRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<ServiceModel>> getServices(String barberId) async {
    return await _remoteDataSource.getServices(barberId);
  }

  @override
  Future<BookingModel> createBooking({
    required String barberId,
    required List<String> serviceIds,
    required String scheduledStart,
    String? staffId,
    bool isHomeService = false,
    String? homeServiceAddressId,
  }) async {
    final data = await _remoteDataSource.createBooking(
      barberId: barberId,
      serviceIds: serviceIds,
      scheduledStart: scheduledStart,
      staffId: staffId,
      isHomeService: isHomeService,
      homeServiceAddressId: homeServiceAddressId,
    );
    return BookingModel.fromJson(data);
  }

  @override
  Future<Map<String, dynamic>> getQueuePosition(String bookingId) async {
    return await _remoteDataSource.getQueuePosition(bookingId);
  }

  @override
  Future<void> cancelBooking(String bookingId, {String? reason}) async {
    await _remoteDataSource.cancelBooking(bookingId, reason: reason);
  }

  @override
  Future<void> updateBookingStatus(String bookingId, String status) async {
    await _remoteDataSource.updateBookingStatus(bookingId, status);
  }

  @override
  Future<List<BookingModel>> getBarberBookings() async {
    return await _remoteDataSource.getBarberBookings();
  }

  @override
  Future<List<BookingModel>> getAllBookings() async {
    return await _remoteDataSource.getCustomerBookings();
  }

  @override
  Future<void> payBooking(String bookingId, String method, String status, String reference) async {
    await _remoteDataSource.payBooking(bookingId, method, status, reference);
  }

  @override
  Future<Map<String, dynamic>> getBookingInvoice(String bookingId) async {
    return await _remoteDataSource.getBookingInvoice(bookingId);
  }

  @override
  Future<List<Map<String, dynamic>>> getAvailableSlots(String barberId, String date) async {
    return await _remoteDataSource.getAvailableSlots(barberId, date);
  }

  @override
  Future<List<BookingModel>> getHomeServiceRequests() async {
    return await _remoteDataSource.getHomeServiceRequests();
  }

  @override
  Future<void> acceptHomeService(String bookingId) async {
    await _remoteDataSource.acceptHomeService(bookingId);
  }

  @override
  Future<void> rejectHomeService(String bookingId, String reason) async {
    await _remoteDataSource.rejectHomeService(bookingId, reason);
  }
}
