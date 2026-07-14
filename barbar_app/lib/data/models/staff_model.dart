class StaffModel {
  final String id;
  final String barberId;
  final String name;
  final String? image;
  final String? phone;
  final String role;
  final bool isActive;
  final double rating;
  final int reviewCount;
  final String? workingDays;
  final String? startTime;
  final String? endTime;
  final String? dayOff;

  StaffModel({
    required this.id,
    required this.barberId,
    required this.name,
    this.image,
    this.phone,
    required this.role,
    required this.isActive,
    required this.rating,
    required this.reviewCount,
    this.workingDays,
    this.startTime,
    this.endTime,
    this.dayOff,
  });

  factory StaffModel.fromJson(Map<String, dynamic> json) {
    return StaffModel(
      id: json['id'] as String,
      barberId: json['barber_id'] as String,
      name: json['name'] as String,
      image: json['image'] as String?,
      phone: json['phone'] as String?,
      role: json['role'] as String? ?? 'staff',
      isActive: json['is_active'] as bool? ?? true,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: json['review_count'] as int? ?? 0,
      workingDays: json['working_days']?.toString(),
      startTime: json['start_time']?.toString(),
      endTime: json['end_time']?.toString(),
      dayOff: json['day_off']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'barber_id': barberId,
      'name': name,
      'image': image,
      'phone': phone,
      'role': role,
      'is_active': isActive,
      'rating': rating,
      'review_count': reviewCount,
      'working_days': workingDays,
      'start_time': startTime,
      'end_time': endTime,
      'day_off': dayOff,
    };
  }

  StaffModel copyWith({
    String? name,
    String? image,
    String? phone,
    String? role,
    bool? isActive,
    String? workingDays,
    String? startTime,
    String? endTime,
    String? dayOff,
  }) {
    return StaffModel(
      id: id,
      barberId: barberId,
      name: name ?? this.name,
      image: image ?? this.image,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      rating: rating,
      reviewCount: reviewCount,
      workingDays: workingDays ?? this.workingDays,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      dayOff: dayOff ?? this.dayOff,
    );
  }
}
