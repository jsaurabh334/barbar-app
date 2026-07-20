import 'vendor_warehouse_model.dart';

class VendorModel {
  final String id;
  final String userId;
  final String businessName;
  final String? businessSlug;
  final String? businessDescription;
  final String? logo;
  final String? banner;
  final String? businessEmail;
  final String? businessPhone;
  final String? address;
  final String? city;
  final String? state;
  final String? pincode;
  final double? latitude;
  final double? longitude;
  final String? gstNumber;
  final String? panNumber;
  final String? businessType;
  final String? website;
  final String status;
  final String kycStatus;
  final double commissionRate;
  final double rating;
  final int reviewCount;
  final int totalProducts;
  final int totalOrders;
  final double totalRevenue;
  final bool isFeatured;
  final bool isVerified;
  final bool isActive;
  final String? returnPolicy;
  final String? shippingPolicy;
  final String? deliveryTimeframe;
  final String? createdAt;
  final List<WarehouseModel>? warehouses;

  VendorModel({
    required this.id,
    required this.userId,
    required this.businessName,
    this.businessSlug,
    this.businessDescription,
    this.logo,
    this.banner,
    this.businessEmail,
    this.businessPhone,
    this.address,
    this.city,
    this.state,
    this.pincode,
    this.latitude,
    this.longitude,
    this.gstNumber,
    this.panNumber,
    this.businessType,
    this.website,
    this.status = 'pending',
    this.kycStatus = 'pending',
    this.commissionRate = 0,
    this.rating = 0,
    this.reviewCount = 0,
    this.totalProducts = 0,
    this.totalOrders = 0,
    this.totalRevenue = 0,
    this.isFeatured = false,
    this.isVerified = false,
    this.isActive = true,
    this.returnPolicy,
    this.shippingPolicy,
    this.deliveryTimeframe,
    this.createdAt,
    this.warehouses,
  });

  factory VendorModel.fromJson(Map<String, dynamic> json) {
    return VendorModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      businessName: json['business_name'] ?? '',
      businessSlug: json['business_slug'],
      businessDescription: json['business_description'],
      logo: json['logo'],
      banner: json['banner'],
      businessEmail: json['business_email'],
      businessPhone: json['business_phone'],
      address: json['address'],
      city: json['city'],
      state: json['state'],
      pincode: json['pincode'],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      gstNumber: json['gst_number'],
      panNumber: json['pan_number'],
      businessType: json['business_type'],
      website: json['website'],
      status: json['status'] ?? 'pending',
      kycStatus: json['kyc_status'] ?? 'pending',
      commissionRate: (json['commission_rate'] as num?)?.toDouble() ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: (json['review_count'] as num?)?.toInt() ?? 0,
      totalProducts: (json['total_products'] as num?)?.toInt() ?? 0,
      totalOrders: (json['total_orders'] as num?)?.toInt() ?? 0,
      totalRevenue: (json['total_revenue'] as num?)?.toDouble() ?? 0,
      isFeatured: json['is_featured'] as bool? ?? false,
      isVerified: json['is_verified'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      returnPolicy: json['return_policy'],
      shippingPolicy: json['shipping_policy'],
      deliveryTimeframe: json['delivery_timeframe'],
      createdAt: json['created_at'],
      warehouses: json['warehouses'] != null
          ? (json['warehouses'] as List<dynamic>)
              .map((e) => WarehouseModel.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'business_name': businessName,
      'business_description': businessDescription,
      'logo': logo,
      'banner': banner,
      'business_email': businessEmail,
      'business_phone': businessPhone,
      'address': address,
      'city': city,
      'state': state,
      'pincode': pincode,
      'latitude': latitude,
      'longitude': longitude,
      'gst_number': gstNumber,
      'pan_number': panNumber,
      'business_type': businessType,
      'website': website,
      'return_policy': returnPolicy,
      'shipping_policy': shippingPolicy,
      'delivery_timeframe': deliveryTimeframe,
    };
  }

  VendorModel copyWith({
    String? businessName,
    String? businessDescription,
    String? logo,
    String? banner,
    String? businessEmail,
    String? businessPhone,
    String? address,
    String? city,
    String? state,
    String? pincode,
    double? latitude,
    double? longitude,
    String? gstNumber,
    String? panNumber,
    String? businessType,
    String? website,
    String? status,
    String? kycStatus,
    bool? isActive,
    String? returnPolicy,
    String? shippingPolicy,
    String? deliveryTimeframe,
    List<WarehouseModel>? warehouses,
  }) {
    return VendorModel(
      id: id,
      userId: userId,
      businessName: businessName ?? this.businessName,
      businessSlug: businessSlug,
      businessDescription: businessDescription ?? this.businessDescription,
      logo: logo ?? this.logo,
      banner: banner ?? this.banner,
      businessEmail: businessEmail ?? this.businessEmail,
      businessPhone: businessPhone ?? this.businessPhone,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      gstNumber: gstNumber ?? this.gstNumber,
      panNumber: panNumber ?? this.panNumber,
      businessType: businessType ?? this.businessType,
      website: website ?? this.website,
      status: status ?? this.status,
      kycStatus: kycStatus ?? this.kycStatus,
      commissionRate: commissionRate,
      rating: rating,
      reviewCount: reviewCount,
      totalProducts: totalProducts,
      totalOrders: totalOrders,
      totalRevenue: totalRevenue,
      isFeatured: isFeatured,
      isVerified: isVerified,
      isActive: isActive ?? this.isActive,
      returnPolicy: returnPolicy ?? this.returnPolicy,
      shippingPolicy: shippingPolicy ?? this.shippingPolicy,
      deliveryTimeframe: deliveryTimeframe ?? this.deliveryTimeframe,
      createdAt: createdAt,
      warehouses: warehouses ?? this.warehouses,
    );
  }
}
