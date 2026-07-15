import '../../data/models/booking_model.dart';
import '../../data/models/service_model.dart';

abstract class BookingRepository {
  Future<List<ServiceModel>> getServices(String barberId);
  Future<BookingModel> createBooking({
    required String barberId,
    required List<String> serviceIds,
    required String scheduledStart,
    String? staffId,
    bool isHomeService = false,
    String? homeServiceAddressId,
  });
  Future<Map<String, dynamic>> getQueuePosition(String bookingId);
  Future<void> cancelBooking(String bookingId, {String? reason});
  Future<void> updateBookingStatus(String bookingId, String status);
  Future<List<BookingModel>> getBarberBookings();
  Future<List<BookingModel>> getAllBookings();
  Future<Map<String, dynamic>> initiateBookingPayment({
    required String bookingId,
    required String gateway,
  });
  Future<void> verifyBookingPayment({
    required String paymentId,
    required String gateway,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  });
  Future<void> payBooking(String bookingId, String method, String status, String reference);
  Future<Map<String, dynamic>> getBookingInvoice(String bookingId);
  Future<List<Map<String, dynamic>>> getAvailableSlots(String barberId, String date);
  Future<List<BookingModel>> getHomeServiceRequests();
  Future<void> acceptHomeService(String bookingId);
  Future<void> rejectHomeService(String bookingId, String reason);
}
