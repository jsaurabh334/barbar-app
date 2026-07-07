import 'package:barbar_app/data/models/user_model.dart';
// Note: assuming BookingModel, ReviewModel exist or we can use generic dynamic map

class AdminCustomerDetailsModel {
  final UserModel customer;
  final double walletBalance;
  final List<dynamic> transactions;
  final List<dynamic> bookings;
  final List<dynamic> reviews;
  final int totalBookings;
  final int completedBookings;
  final int cancelledBookings;
  final double spent;
  final double rating;

  AdminCustomerDetailsModel({
    required this.customer,
    required this.walletBalance,
    required this.transactions,
    required this.bookings,
    required this.reviews,
    required this.totalBookings,
    required this.completedBookings,
    required this.cancelledBookings,
    required this.spent,
    required this.rating,
  });

  factory AdminCustomerDetailsModel.fromJson(Map<String, dynamic> json) {
    final customerJson = json['customer'] ?? {};
    final walletJson = json['wallet'] ?? {};
    final statsJson = json['stats'] ?? {};

    return AdminCustomerDetailsModel(
      customer: UserModel.fromJson(customerJson),
      walletBalance: (walletJson['balance'] ?? 0).toDouble(),
      transactions: List<dynamic>.from(walletJson['transactions'] ?? []),
      bookings: List<dynamic>.from(json['bookings'] ?? []),
      reviews: List<dynamic>.from(json['reviews'] ?? []),
      totalBookings: statsJson['total_bookings'] ?? 0,
      completedBookings: statsJson['completed'] ?? 0,
      cancelledBookings: statsJson['cancelled'] ?? 0,
      spent: (statsJson['spent'] ?? 0).toDouble(),
      rating: (statsJson['rating'] ?? 0).toDouble(),
    );
  }
}
