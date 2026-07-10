import '../../data/models/booking_model.dart';
import '../../data/models/service_model.dart';

abstract class BookingRepository {
  Future<List<ServiceModel>> getServices(String barberId);
  Future<BookingModel> createBooking({
    required String barberId,
    required List<String> serviceIds,
    required String scheduledStart,
    bool isHomeService,
    String? homeServiceAddressId,
  });
  Future<Map<String, dynamic>> getQueuePosition(String bookingId);
  Future<void> cancelBooking(String bookingId, {String? reason});
  Future<void> updateBookingStatus(String bookingId, String status);
  Future<List<BookingModel>> getBarberBookings();
  Future<List<BookingModel>> getAllBookings();
  Future<void> payBooking(String bookingId, String method, String status, String reference);
  Future<Map<String, dynamic>> getBookingInvoice(String bookingId);
  Future<List<Map<String, dynamic>>> getAvailableSlots(String barberId, String date);
}
