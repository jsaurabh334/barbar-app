import '../../data/models/booking_model.dart';
import '../../data/models/service_model.dart';

abstract class BookingRepository {
  Future<List<ServiceModel>> getServices(String barberId);
  Future<BookingModel> createBooking({
    required String barberId,
    required List<String> serviceIds,
    required String scheduledStart,
  });
  Future<Map<String, dynamic>> getQueuePosition(String bookingId);
  Future<void> updateBookingStatus(String bookingId, String status);
  Future<List<BookingModel>> getAllBookings();
  Future<List<BookingModel>> getBarberBookings();
  Future<void> payBooking(String bookingId, String method, String status, String reference);
  Future<Map<String, dynamic>> getBookingInvoice(String bookingId);
}
