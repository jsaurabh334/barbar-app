class BarberModel {
  final String id;
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

  BarberModel({
    required this.id,
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
  });

  factory BarberModel.fromJson(Map<String, dynamic> json) {
    return BarberModel(
      id: json['id'] as String,
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
    };
  }

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
    );
  }
}
