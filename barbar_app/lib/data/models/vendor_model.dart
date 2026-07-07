import 'package:barbar_app/data/models/user_model.dart';

class VendorModel {
  final String id;
  final String userId;
  final String storeName;
  final String? storeLogo;
  final String status;
  final String kycStatus;
  final double rating;
  final double totalRevenue;
  final String city;
  final String? storePhone;
  final UserModel? user;

  VendorModel({
    required this.id,
    required this.userId,
    required this.storeName,
    this.storeLogo,
    required this.status,
    required this.kycStatus,
    required this.rating,
    required this.totalRevenue,
    required this.city,
    this.storePhone,
    this.user,
  });

  factory VendorModel.fromJson(Map<String, dynamic> json) {
    return VendorModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      storeName: json['store_name'] ?? '',
      storeLogo: json['store_logo'],
      status: json['status'] ?? 'pending',
      kycStatus: json['kyc_status'] ?? 'pending',
      rating: (json['rating'] ?? 0).toDouble(),
      totalRevenue: (json['total_revenue'] ?? 0).toDouble(),
      city: json['city'] ?? '',
      storePhone: json['store_phone'],
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'store_name': storeName,
      'store_logo': storeLogo,
      'status': status,
      'kyc_status': kycStatus,
      'rating': rating,
      'total_revenue': totalRevenue,
      'city': city,
      'store_phone': storePhone,
      'user': user?.toJson(),
    };
  }

  VendorModel copyWith({
    String? status,
    String? kycStatus,
  }) {
    return VendorModel(
      id: id,
      userId: userId,
      storeName: storeName,
      storeLogo: storeLogo,
      status: status ?? this.status,
      kycStatus: kycStatus ?? this.kycStatus,
      rating: rating,
      totalRevenue: totalRevenue,
      city: city,
      storePhone: storePhone,
      user: user,
    );
  }
}
