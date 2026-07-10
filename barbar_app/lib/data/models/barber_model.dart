import '../../core/constants/constants.dart';

class BarberModel {
  final String id;
  final String? userId;
  final String shopName;
  final String? shopDescription;
  final String? shopImage;
  final String address;
  final String city;
  final double latitude;
  final double longitude;
  final double rating;
  final int reviewCount;
  final bool isAvailable;
  final int currentQueueLength;
  final double averageWaitTime;
  final String? verificationStatus;
  final String? status;
  final String? ownerName;
  final String? phone;
  final List<dynamic>? services;
  final List<dynamic>? documents;
  final String? createdAt;
  final List<String>? shopImages;
  final List<dynamic>? businessDays;
  final List<String>? tags;
  final List<String>? amenities;
  final bool isHomeServiceAvailable;
  final double serviceRadiusKm;
  final double travelChargePerKm;
  final double baseTravelCharge;
  final String? startTime;
  final String? endTime;

  BarberModel({
    required this.id,
    this.userId,
    required this.shopName,
    this.shopDescription,
    this.shopImage,
    required this.address,
    required this.city,
    required this.latitude,
    required this.longitude,
    required this.rating,
    required this.reviewCount,
    required this.isAvailable,
    required this.currentQueueLength,
    required this.averageWaitTime,
    this.verificationStatus,
    this.status,
    this.ownerName,
    this.phone,
    this.services,
    this.documents,
    this.createdAt,
    this.shopImages,
    this.businessDays,
    this.tags,
    this.amenities,
    this.isHomeServiceAvailable = false,
    this.serviceRadiusKm = 0,
    this.travelChargePerKm = 0,
    this.baseTravelCharge = 0,
    this.startTime,
    this.endTime,
  });

  factory BarberModel.fromJson(Map<String, dynamic> json) {
    return BarberModel(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      shopName: json['shop_name'] as String,
      shopDescription: json['shop_description'] as String?,
      shopImage: json['shop_image'] as String?,
      address: json['address'] as String,
      city: json['city'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      rating: (json['rating'] as num).toDouble(),
      reviewCount: (json['review_count'] as num?)?.toInt() ?? 0,
      isAvailable: json['is_available'] as bool? ?? true,
      currentQueueLength: (json['current_queue_length'] as num?)?.toInt() ?? 0,
      averageWaitTime: (json['average_wait_time'] as num?)?.toDouble() ?? 0.0,
      verificationStatus: json['verification_status'] as String?,
      status: json['status'] as String?,
      ownerName: json['user'] != null ? json['user']['full_name'] as String? : null,
      phone: json['user'] != null ? json['user']['phone'] as String? : json['phone'] as String?,
      services: json['services'] as List<dynamic>?,
      documents: json['documents'] as List<dynamic>?,
      createdAt: json['created_at'] as String?,
      shopImages: json['shop_images'] != null
          ? (json['shop_images'] as List<dynamic>).cast<String>()
          : null,
      businessDays: json['business_days'] as List<dynamic>?,
      tags: json['tags'] != null
          ? (json['tags'] as List<dynamic>).cast<String>()
          : null,
      amenities: json['amenities'] != null
          ? (json['amenities'] as List<dynamic>).cast<String>()
          : null,
      startTime: json['start_time'] as String?,
      endTime: json['end_time'] as String?,
      isHomeServiceAvailable: json['is_home_service_available'] as bool? ?? false,
      serviceRadiusKm: (json['service_radius_km'] as num?)?.toDouble() ?? 0,
      travelChargePerKm: (json['travel_charge_per_km'] as num?)?.toDouble() ?? 0,
      baseTravelCharge: (json['base_travel_charge'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shop_name': shopName,
      'shop_description': shopDescription,
      'shop_image': shopImage,
      'address': address,
      'city': city,
      'latitude': latitude,
      'longitude': longitude,
      'rating': rating,
      'review_count': reviewCount,
      'is_available': isAvailable,
      'current_queue_length': currentQueueLength,
      'average_wait_time': averageWaitTime,
      'verification_status': verificationStatus,
      'status': status,
      'services': services,
      'documents': documents,
      'created_at': createdAt,
      'shop_images': shopImages,
      'business_days': businessDays,
      'tags': tags,
      'amenities': amenities,
      'is_home_service_available': isHomeServiceAvailable,
      'service_radius_km': serviceRadiusKm,
      'travel_charge_per_km': travelChargePerKm,
      'base_travel_charge': baseTravelCharge,
      'start_time': startTime,
      'end_time': endTime,
    };
  }

  static String getFullImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    final base = AppConfig.apiBaseUrl.replaceAll('/api/v1/', '/');
    return '$base${path.startsWith('/') ? path.substring(1) : path}';
  }

  String? get fullShopImage {
    if (shopImage != null && shopImage!.isNotEmpty) {
      return getFullImageUrl(shopImage);
    }
    final images = fullShopImages;
    return images.isNotEmpty ? images.first : null;
  }

  List<String> get fullShopImages => shopImages
      ?.map((e) => getFullImageUrl(e))
      .where((e) => e.isNotEmpty)
      .toList() ?? [];

  BarberModel copyWith({
    String? id,
    String? shopName,
    String? shopDescription,
    String? shopImage,
    String? address,
    String? city,
    double? latitude,
    double? longitude,
    double? rating,
    int? reviewCount,
    bool? isAvailable,
    int? currentQueueLength,
    double? averageWaitTime,
    String? verificationStatus,
    String? status,
    String? ownerName,
    String? phone,
    List<dynamic>? services,
    List<dynamic>? documents,
    String? createdAt,
    List<String>? shopImages,
    List<dynamic>? businessDays,
    List<String>? tags,
    List<String>? amenities,
    bool? isHomeServiceAvailable,
    double? serviceRadiusKm,
    double? travelChargePerKm,
    double? baseTravelCharge,
    String? startTime,
    String? endTime,
  }) {
    return BarberModel(
      id: id ?? this.id,
      shopName: shopName ?? this.shopName,
      shopDescription: shopDescription ?? this.shopDescription,
      shopImage: shopImage ?? this.shopImage,
      address: address ?? this.address,
      city: city ?? this.city,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      isAvailable: isAvailable ?? this.isAvailable,
      currentQueueLength: currentQueueLength ?? this.currentQueueLength,
      averageWaitTime: averageWaitTime ?? this.averageWaitTime,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      status: status ?? this.status,
      ownerName: ownerName ?? this.ownerName,
      phone: phone ?? this.phone,
      services: services ?? this.services,
      documents: documents ?? this.documents,
      createdAt: createdAt ?? this.createdAt,
      shopImages: shopImages ?? this.shopImages,
      businessDays: businessDays ?? this.businessDays,
      tags: tags ?? this.tags,
      amenities: amenities ?? this.amenities,
      isHomeServiceAvailable: isHomeServiceAvailable ?? this.isHomeServiceAvailable,
      serviceRadiusKm: serviceRadiusKm ?? this.serviceRadiusKm,
      travelChargePerKm: travelChargePerKm ?? this.travelChargePerKm,
      baseTravelCharge: baseTravelCharge ?? this.baseTravelCharge,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }
}
