import '../../core/constants/constants.dart';

class BarberModel {
  final String id;
  final String? userId;
  final String shopName;
  final String? shopDescription;
  final String? shopImage;
  final String address;
  final String city;
  final String? state;
  final String? pincode;
  final double latitude;
  final double longitude;
  final double rating;
  final int reviewCount;
  final int totalBookings;
  final bool isAvailable;
  final int currentQueueLength;
  final double averageWaitTime;
  final String? verificationStatus;
  final String? status;
  final String? ownerName;
  final String? phone;
  final String? alternatePhone;
  final String? email;
  final int experienceYears;
  final String? startTime;
  final String? endTime;
  final String? breakStartTime;
  final String? breakEndTime;
  final int slotDuration;
  final int bufferBetweenSlots;
  final int maxQueueSize;
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

  BarberModel({
    required this.id,
    this.userId,
    required this.shopName,
    this.shopDescription,
    this.shopImage,
    required this.address,
    required this.city,
    this.state,
    this.pincode,
    required this.latitude,
    required this.longitude,
    required this.rating,
    required this.reviewCount,
    this.totalBookings = 0,
    required this.isAvailable,
    required this.currentQueueLength,
    required this.averageWaitTime,
    this.verificationStatus,
    this.status,
    this.ownerName,
    this.phone,
    this.alternatePhone,
    this.email,
    this.experienceYears = 0,
    this.startTime,
    this.endTime,
    this.breakStartTime,
    this.breakEndTime,
    this.slotDuration = 30,
    this.bufferBetweenSlots = 5,
    this.maxQueueSize = 50,
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
      state: json['state'] as String?,
      pincode: json['pincode'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      rating: (json['rating'] as num).toDouble(),
      reviewCount: (json['review_count'] as num?)?.toInt() ?? 0,
      totalBookings: (json['total_bookings'] as num?)?.toInt() ?? 0,
      isAvailable: json['is_available'] as bool? ?? true,
      currentQueueLength: (json['current_queue_length'] as num?)?.toInt() ?? 0,
      averageWaitTime: (json['average_wait_time'] as num?)?.toDouble() ?? 0.0,
      verificationStatus: json['verification_status'] as String?,
      status: json['status'] as String?,
      ownerName: json['user'] != null ? json['user']['full_name'] as String? : null,
      phone: json['user'] != null ? json['user']['phone'] as String? : json['phone'] as String?,
      alternatePhone: json['alternate_phone'] as String?,
      email: json['email'] as String?,
      experienceYears: (json['experience_years'] as num?)?.toInt() ?? 0,
      startTime: json['start_time'] as String?,
      endTime: json['end_time'] as String?,
      breakStartTime: json['break_start_time'] as String?,
      breakEndTime: json['break_end_time'] as String?,
      slotDuration: (json['slot_duration'] as num?)?.toInt() ?? 30,
      bufferBetweenSlots: (json['buffer_between_slots'] as num?)?.toInt() ?? 5,
      maxQueueSize: (json['max_queue_size'] as num?)?.toInt() ?? 50,
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
      'state': state,
      'pincode': pincode,
      'latitude': latitude,
      'longitude': longitude,
      'rating': rating,
      'review_count': reviewCount,
      'total_bookings': totalBookings,
      'is_available': isAvailable,
      'current_queue_length': currentQueueLength,
      'average_wait_time': averageWaitTime,
      'verification_status': verificationStatus,
      'status': status,
      'phone': phone,
      'alternate_phone': alternatePhone,
      'email': email,
      'experience_years': experienceYears,
      'start_time': startTime,
      'end_time': endTime,
      'break_start_time': breakStartTime,
      'break_end_time': breakEndTime,
      'slot_duration': slotDuration,
      'buffer_between_slots': bufferBetweenSlots,
      'max_queue_size': maxQueueSize,
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
    String? state,
    String? pincode,
    double? latitude,
    double? longitude,
    double? rating,
    int? reviewCount,
    int? totalBookings,
    bool? isAvailable,
    int? currentQueueLength,
    double? averageWaitTime,
    String? verificationStatus,
    String? status,
    String? ownerName,
    String? phone,
    String? alternatePhone,
    String? email,
    int? experienceYears,
    String? startTime,
    String? endTime,
    String? breakStartTime,
    String? breakEndTime,
    int? slotDuration,
    int? bufferBetweenSlots,
    int? maxQueueSize,
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
  }) {
    return BarberModel(
      id: id ?? this.id,
      shopName: shopName ?? this.shopName,
      shopDescription: shopDescription ?? this.shopDescription,
      shopImage: shopImage ?? this.shopImage,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      totalBookings: totalBookings ?? this.totalBookings,
      isAvailable: isAvailable ?? this.isAvailable,
      currentQueueLength: currentQueueLength ?? this.currentQueueLength,
      averageWaitTime: averageWaitTime ?? this.averageWaitTime,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      status: status ?? this.status,
      ownerName: ownerName ?? this.ownerName,
      phone: phone ?? this.phone,
      alternatePhone: alternatePhone ?? this.alternatePhone,
      email: email ?? this.email,
      experienceYears: experienceYears ?? this.experienceYears,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      breakStartTime: breakStartTime ?? this.breakStartTime,
      breakEndTime: breakEndTime ?? this.breakEndTime,
      slotDuration: slotDuration ?? this.slotDuration,
      bufferBetweenSlots: bufferBetweenSlots ?? this.bufferBetweenSlots,
      maxQueueSize: maxQueueSize ?? this.maxQueueSize,
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
    );
  }
}
