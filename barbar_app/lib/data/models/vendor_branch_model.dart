import 'vendor_working_hour_model.dart';
import 'vendor_holiday_model.dart';
import 'vendor_image_model.dart';

class VendorBranchModel {
  final String id;
  final String vendorId;
  final String name;
  final String? phone;
  final String? email;
  final String address;
  final String city;
  final String? state;
  final String? pincode;
  final double? latitude;
  final double? longitude;
  final String? timezone;
  final String status;
  final bool isDefault;
  final bool isActive;
  final int displayOrder;
  final String? createdAt;
  final String? updatedAt;
  final List<VendorWorkingHourModel>? workingHours;
  final List<VendorHolidayModel>? holidays;
  final List<VendorImageModel>? images;

  VendorBranchModel({
    required this.id,
    required this.vendorId,
    required this.name,
    this.phone,
    this.email,
    required this.address,
    required this.city,
    this.state,
    this.pincode,
    this.latitude,
    this.longitude,
    this.timezone,
    this.status = 'active',
    this.isDefault = false,
    this.isActive = true,
    this.displayOrder = 0,
    this.createdAt,
    this.updatedAt,
    this.workingHours,
    this.holidays,
    this.images,
  });

  factory VendorBranchModel.fromJson(Map<String, dynamic> json) {
    return VendorBranchModel(
      id: json['id'] ?? '',
      vendorId: json['vendor_id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'],
      email: json['email'],
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      state: json['state'],
      pincode: json['pincode'],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      timezone: json['timezone'],
      status: json['status'] ?? 'active',
      isDefault: json['is_default'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      displayOrder: (json['display_order'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      workingHours: json['working_hours'] != null
          ? (json['working_hours'] as List<dynamic>)
              .map((e) => VendorWorkingHourModel.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      holidays: json['holidays'] != null
          ? (json['holidays'] as List<dynamic>)
              .map((e) => VendorHolidayModel.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      images: json['images'] != null
          ? (json['images'] as List<dynamic>)
              .map((e) => VendorImageModel.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'city': city,
      'state': state,
      'pincode': pincode,
      'latitude': latitude,
      'longitude': longitude,
      'timezone': timezone,
      'is_default': isDefault,
      'is_active': isActive,
      'display_order': displayOrder,
    };
  }
}
