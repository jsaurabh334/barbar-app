import 'vendor_branch_model.dart';
import 'vendor_image_model.dart';

class VendorModel {
  final String id;
  final String userId;
  final String storeName;
  final String? storeSlug;
  final String? storeDescription;
  final String? storeLogo;
  final String? storeBanner;
  final String? storeEmail;
  final String? storePhone;
  final String? address;
  final String? city;
  final String? state;
  final String? pincode;
  final double? latitude;
  final double? longitude;
  final String? gstNumber;
  final String? panNumber;
  final String? fssaiNumber;
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
  final List<VendorBranchModel>? branches;
  final List<VendorImageModel>? images;

  VendorModel({
    required this.id,
    required this.userId,
    required this.storeName,
    this.storeSlug,
    this.storeDescription,
    this.storeLogo,
    this.storeBanner,
    this.storeEmail,
    this.storePhone,
    this.address,
    this.city,
    this.state,
    this.pincode,
    this.latitude,
    this.longitude,
    this.gstNumber,
    this.panNumber,
    this.fssaiNumber,
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
    this.branches,
    this.images,
  });

  factory VendorModel.fromJson(Map<String, dynamic> json) {
    return VendorModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      storeName: json['store_name'] ?? '',
      storeSlug: json['store_slug'],
      storeDescription: json['store_description'],
      storeLogo: json['store_logo'],
      storeBanner: json['store_banner'],
      storeEmail: json['store_email'],
      storePhone: json['store_phone'],
      address: json['address'],
      city: json['city'],
      state: json['state'],
      pincode: json['pincode'],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      gstNumber: json['gst_number'],
      panNumber: json['pan_number'],
      fssaiNumber: json['fssai_number'],
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
      branches: json['branches'] != null
          ? (json['branches'] as List<dynamic>)
              .map((e) => VendorBranchModel.fromJson(e as Map<String, dynamic>))
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
      'store_name': storeName,
      'store_description': storeDescription,
      'store_logo': storeLogo,
      'store_banner': storeBanner,
      'store_email': storeEmail,
      'store_phone': storePhone,
      'address': address,
      'city': city,
      'state': state,
      'pincode': pincode,
      'latitude': latitude,
      'longitude': longitude,
      'gst_number': gstNumber,
      'pan_number': panNumber,
      'fssai_number': fssaiNumber,
      'business_type': businessType,
      'website': website,
      'return_policy': returnPolicy,
      'shipping_policy': shippingPolicy,
      'delivery_timeframe': deliveryTimeframe,
    };
  }

  VendorModel copyWith({
    String? storeName,
    String? storeDescription,
    String? storeLogo,
    String? storeBanner,
    String? storeEmail,
    String? storePhone,
    String? address,
    String? city,
    String? state,
    String? pincode,
    double? latitude,
    double? longitude,
    String? gstNumber,
    String? panNumber,
    String? fssaiNumber,
    String? businessType,
    String? website,
    String? status,
    String? kycStatus,
    bool? isActive,
    String? returnPolicy,
    String? shippingPolicy,
    String? deliveryTimeframe,
    List<VendorBranchModel>? branches,
    List<VendorImageModel>? images,
  }) {
    return VendorModel(
      id: id,
      userId: userId,
      storeName: storeName ?? this.storeName,
      storeSlug: storeSlug,
      storeDescription: storeDescription ?? this.storeDescription,
      storeLogo: storeLogo ?? this.storeLogo,
      storeBanner: storeBanner ?? this.storeBanner,
      storeEmail: storeEmail ?? this.storeEmail,
      storePhone: storePhone ?? this.storePhone,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      gstNumber: gstNumber ?? this.gstNumber,
      panNumber: panNumber ?? this.panNumber,
      fssaiNumber: fssaiNumber ?? this.fssaiNumber,
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
      branches: branches ?? this.branches,
      images: images ?? this.images,
    );
  }
}
