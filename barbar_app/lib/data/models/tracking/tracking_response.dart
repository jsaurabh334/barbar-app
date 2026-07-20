class TrackingResponse {
  final int version;
  final String status;
  final DriverInfo? driver;
  final WarehouseInfo? warehouse;
  final CustomerInfo? customer;
  final EtaInfo? eta;
  final List<TimelineEntry> timeline;

  final String? deliveryOtp;
  final int? expiresInSeconds;

  TrackingResponse({
    required this.version,
    required this.status,
    this.driver,
    this.warehouse,
    this.customer,
    this.eta,
    required this.timeline,
    this.deliveryOtp,
    this.expiresInSeconds,
  });

  factory TrackingResponse.fromJson(Map<String, dynamic> json) {
    return TrackingResponse(
      version: json['version'] as int? ?? 1,
      status: json['status'] as String? ?? '',
      driver: json['driver'] != null
          ? DriverInfo.fromJson(json['driver'] as Map<String, dynamic>)
          : null,
      warehouse: json['warehouse'] != null
          ? WarehouseInfo.fromJson(json['warehouse'] as Map<String, dynamic>)
          : null,
      customer: json['customer'] != null
          ? CustomerInfo.fromJson(json['customer'] as Map<String, dynamic>)
          : null,
      eta: json['eta'] != null
          ? EtaInfo.fromJson(json['eta'] as Map<String, dynamic>)
          : null,
      timeline: (json['timeline'] as List<dynamic>?)
              ?.map((e) => TimelineEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      deliveryOtp: json['delivery_otp'] as String?,
      expiresInSeconds: json['expires_in_seconds'] as int?,
    );
  }

  TrackingResponse copyWith({
    String? status,
    DriverInfo? driver,
    EtaInfo? eta,
    List<TimelineEntry>? timeline,
    String? deliveryOtp,
    int? expiresInSeconds,
  }) {
    return TrackingResponse(
      version: version,
      status: status ?? this.status,
      driver: driver ?? this.driver,
      warehouse: warehouse,
      customer: customer,
      eta: eta ?? this.eta,
      timeline: timeline ?? this.timeline,
      deliveryOtp: deliveryOtp ?? this.deliveryOtp,
      expiresInSeconds: expiresInSeconds ?? this.expiresInSeconds,
    );
  }
}

class DriverInfo {
  final String id;
  final String name;
  final String avatar;
  final String phone;
  final String vehicleType;
  final String vehicleNumber;
  final double rating;
  final double? latitude;
  final double? longitude;
  final double? bearing;
  final double? speed;

  DriverInfo({
    required this.id,
    required this.name,
    this.avatar = '',
    this.phone = '',
    this.vehicleType = '',
    this.vehicleNumber = '',
    this.rating = 0,
    this.latitude,
    this.longitude,
    this.bearing,
    this.speed,
  });

  factory DriverInfo.fromJson(Map<String, dynamic> json) {
    return DriverInfo(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      avatar: json['avatar'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      vehicleType: json['vehicle_type'] as String? ?? '',
      vehicleNumber: json['vehicle_number'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      bearing: (json['bearing'] as num?)?.toDouble(),
      speed: (json['speed'] as num?)?.toDouble(),
    );
  }

  DriverInfo copyWith({
    double? latitude,
    double? longitude,
    double? bearing,
    double? speed,
  }) {
    return DriverInfo(
      id: id,
      name: name,
      avatar: avatar,
      phone: phone,
      vehicleType: vehicleType,
      vehicleNumber: vehicleNumber,
      rating: rating,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      bearing: bearing ?? this.bearing,
      speed: speed ?? this.speed,
    );
  }
}

class WarehouseInfo {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String address;

  WarehouseInfo({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.address = '',
  });

  factory WarehouseInfo.fromJson(Map<String, dynamic> json) {
    return WarehouseInfo(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      address: json['address'] as String? ?? '',
    );
  }
}

class CustomerInfo {
  final double latitude;
  final double longitude;
  final String fullAddress;

  CustomerInfo({
    required this.latitude,
    required this.longitude,
    this.fullAddress = '',
  });

  factory CustomerInfo.fromJson(Map<String, dynamic> json) {
    return CustomerInfo(
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      fullAddress: json['full_address'] as String? ?? '',
    );
  }
}

class EtaInfo {
  final double minutes;
  final double distanceKm;

  EtaInfo({required this.minutes, required this.distanceKm});

  factory EtaInfo.fromJson(Map<String, dynamic> json) {
    return EtaInfo(
      minutes: (json['minutes'] as num?)?.toDouble() ?? 0,
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0,
    );
  }
}

class TimelineEntry {
  final String status;
  final String timestamp;
  final String note;

  TimelineEntry({
    required this.status,
    required this.timestamp,
    this.note = '',
  });

  factory TimelineEntry.fromJson(Map<String, dynamic> json) {
    return TimelineEntry(
      status: json['status'] as String? ?? '',
      timestamp: json['timestamp'] as String? ?? '',
      note: json['note'] as String? ?? '',
    );
  }
}
