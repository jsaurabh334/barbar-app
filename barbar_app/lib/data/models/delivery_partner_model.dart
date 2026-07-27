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

  static double _parseDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0.0;
    return 0.0;
  }

  factory DeliveryPartnerModel.fromJson(Map<String, dynamic> json) {
    return DeliveryPartnerModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      vehicleType: json['vehicle_type'] as String? ?? '',
      vehicleNumber: json['vehicle_number'] as String? ?? '',
      licenseNumber: json['license_number'] as String? ?? '',
      currentLatitude: _parseDouble(json['current_latitude']),
      currentLongitude: _parseDouble(json['current_longitude']),
      availabilityStatus: json['availability_status'] as String? ?? 'offline',
      rating: _parseDouble(json['rating']),
      user: json['user'] != null && json['user'] is Map<String, dynamic>
          ? UserModel.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      status: json['status'] as String? ?? 'pending',
      rejectionReason: json['rejection_reason'] as String?,
      approvedAt: json['approved_at'] != null ? DateTime.tryParse(json['approved_at'].toString()) : null,
      suspendedAt: json['suspended_at'] != null ? DateTime.tryParse(json['suspended_at'].toString()) : null,
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
