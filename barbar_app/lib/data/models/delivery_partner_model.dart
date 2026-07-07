import 'package:barbar_app/data/models/user_model.dart';

class DeliveryPartnerModel {
  final String id;
  final String userId;
  final String vehicleType;
  final String licenseNumber;
  final double currentLatitude;
  final double currentLongitude;
  final String availabilityStatus;
  final double rating;
  final UserModel? user; // Optional nested user object from join

  DeliveryPartnerModel({
    required this.id,
    required this.userId,
    required this.vehicleType,
    required this.licenseNumber,
    required this.currentLatitude,
    required this.currentLongitude,
    required this.availabilityStatus,
    required this.rating,
    this.user,
  });

  factory DeliveryPartnerModel.fromJson(Map<String, dynamic> json) {
    return DeliveryPartnerModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      vehicleType: json['vehicle_type'] ?? '',
      licenseNumber: json['license_number'] ?? '',
      currentLatitude: (json['current_latitude'] ?? 0.0).toDouble(),
      currentLongitude: (json['current_longitude'] ?? 0.0).toDouble(),
      availabilityStatus: json['availability_status'] ?? 'offline',
      rating: (json['rating'] ?? 0.0).toDouble(),
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'vehicle_type': vehicleType,
      'license_number': licenseNumber,
      'current_latitude': currentLatitude,
      'current_longitude': currentLongitude,
      'availability_status': availabilityStatus,
      'rating': rating,
      'user': user?.toJson(),
    };
  }

  DeliveryPartnerModel copyWith({
    String? availabilityStatus,
  }) {
    return DeliveryPartnerModel(
      id: id,
      userId: userId,
      vehicleType: vehicleType,
      licenseNumber: licenseNumber,
      currentLatitude: currentLatitude,
      currentLongitude: currentLongitude,
      availabilityStatus: availabilityStatus ?? this.availabilityStatus,
      rating: rating,
      user: user,
    );
  }
}
