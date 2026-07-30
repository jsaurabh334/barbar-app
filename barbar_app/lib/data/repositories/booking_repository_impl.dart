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
  Future<BookingModel> getBookingById(String bookingId) async {
    return await _remoteDataSource.getBookingById(bookingId);
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
  Future<Map<String, dynamic>> initiateBookingPayment({
    required String bookingId,
    required String gateway,
  }) async {
    return await _remoteDataSource.initiateBookingPayment(
      bookingId: bookingId,
      gateway: gateway,
    );
  }

  @override
  Future<void> verifyBookingPayment({
    required String paymentId,
    required String gateway,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    await _remoteDataSource.verifyBookingPayment(
      paymentId: paymentId,
      gateway: gateway,
      razorpayOrderId: razorpayOrderId,
      razorpayPaymentId: razorpayPaymentId,
      razorpaySignature: razorpaySignature,
    );
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
  Future<List<Map<String, dynamic>>> getAvailableSlots(String barberId, String date, {String? serviceIds, String? staffId}) async {
    return await _remoteDataSource.getAvailableSlots(barberId, date, serviceIds: serviceIds, staffId: staffId);
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

  @override
  Future<void> checkIn(String bookingId, String method, {String? token, double? lat, double? lng}) async {
    await _remoteDataSource.checkIn(bookingId, method, token: token, lat: lat, lng: lng);
  }

  @override
  Future<void> imComing(String bookingId) async {
    await _remoteDataSource.imComing(bookingId);
  }

  @override
  Future<Map<String, dynamic>> getCallPermission(String bookingId) async {
    return await _remoteDataSource.getCallPermission(bookingId);
  }

  @override
  Future<Map<String, dynamic>> getTodayQueue({String? staffId}) async {
    return await _remoteDataSource.getTodayQueue(staffId: staffId);
  }

  @override
  Future<void> skipCustomer(String bookingId) async {
    await _remoteDataSource.skipCustomer(bookingId);
  }

  @override
  Future<void> startService(String bookingId) async {
    await _remoteDataSource.startService(bookingId);
  }

  @override
  Future<void> completeService(String bookingId) async {
    await _remoteDataSource.completeService(bookingId);
  }

  @override
  Future<void> markNoShow(String bookingId) async {
    await _remoteDataSource.markNoShow(bookingId);
  }
}
