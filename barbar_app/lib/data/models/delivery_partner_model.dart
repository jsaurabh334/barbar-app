import 'package:barbar_app/data/models/user_model.dart';

class DeliveryPartnerModel {
  final String id;
  final String userId;
  final String vehicleType;
  final String vehicleNumber;
  final String licenseNumber;
  final double currentLatitude;
  final double currentLongitude;
  final String availabilityStatus;
  final double rating;
  final UserModel? user;
  final String status;
  final String? rejectionReason;
  final DateTime? approvedAt;
  final DateTime? suspendedAt;

  DeliveryPartnerModel({
    required this.id,
    required this.userId,
    required this.vehicleType,
    this.vehicleNumber = '',
    required this.licenseNumber,
    required this.currentLatitude,
    required this.currentLongitude,
    required this.availabilityStatus,
    required this.rating,
    this.user,
    this.status = 'pending',
    this.rejectionReason,
    this.approvedAt,
    this.suspendedAt,
  });

  bool get isApproved => status == 'approved';
  bool get isPending => status == 'pending';
  bool get isRejected => status == 'rejected';
  bool get isSuspended => status == 'suspended';

  factory DeliveryPartnerModel.fromJson(Map<String, dynamic> json) {
    return DeliveryPartnerModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      vehicleType: json['vehicle_type'] ?? '',
      vehicleNumber: json['vehicle_number'] ?? '',
      licenseNumber: json['license_number'] ?? '',
      currentLatitude: (json['current_latitude'] ?? 0.0).toDouble(),
      currentLongitude: (json['current_longitude'] ?? 0.0).toDouble(),
      availabilityStatus: json['availability_status'] ?? 'offline',
      rating: (json['rating'] ?? 0.0).toDouble(),
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
      status: json['status'] ?? 'pending',
      rejectionReason: json['rejection_reason'],
      approvedAt: json['approved_at'] != null ? DateTime.parse(json['approved_at']) : null,
      suspendedAt: json['suspended_at'] != null ? DateTime.parse(json['suspended_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'vehicle_type': vehicleType,
      'vehicle_number': vehicleNumber,
      'license_number': licenseNumber,
      'current_latitude': currentLatitude,
      'current_longitude': currentLongitude,
      'availability_status': availabilityStatus,
      'rating': rating,
      'user': user?.toJson(),
      'status': status,
      'rejection_reason': rejectionReason,
    };
  }

  DeliveryPartnerModel copyWith({
    String? availabilityStatus,
    String? status,
    String? rejectionReason,
  }) {
    return DeliveryPartnerModel(
      id: id,
      userId: userId,
      vehicleType: vehicleType,
      vehicleNumber: vehicleNumber,
      licenseNumber: licenseNumber,
      currentLatitude: currentLatitude,
      currentLongitude: currentLongitude,
      availabilityStatus: availabilityStatus ?? this.availabilityStatus,
      rating: rating,
      user: user,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      approvedAt: approvedAt,
      suspendedAt: suspendedAt,
    );
  }
}
