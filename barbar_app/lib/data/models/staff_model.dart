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
  final String? bio;
  final int experienceYears;
  final List<String> languages;
  final String? specializations;
  final String? instagram;
  final String? workingDays;
  final String? startTime;
  final String? endTime;
  final String? dayOff;
  final List<Map<String, dynamic>>? services;

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
    this.bio,
    this.experienceYears = 0,
    this.languages = const [],
    this.specializations,
    this.instagram,
    this.workingDays,
    this.startTime,
    this.endTime,
    this.dayOff,
    this.services,
  });

  String get roleLabel => role == 'manager' ? 'Manager' : 'Specialist';

  String get ratingDisplay => rating > 0 ? rating.toStringAsFixed(1) : 'New';

  factory StaffModel.fromJson(Map<String, dynamic> json) {
    List<String> parsedLanguages = [];
    final rawLangs = json['languages'];
    if (rawLangs is List) {
      parsedLanguages = rawLangs.map((e) => e.toString()).toList();
    }

    List<Map<String, dynamic>>? parsedServices;
    final rawServices = json['services'];
    if (rawServices is List) {
      parsedServices = rawServices.cast<Map<String, dynamic>>();
    }

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
      bio: json['bio'] as String?,
      experienceYears: (json['experience_years'] as num?)?.toInt() ?? 0,
      languages: parsedLanguages,
      specializations: json['specializations'] as String?,
      instagram: json['instagram'] as String?,
      workingDays: json['working_days']?.toString(),
      startTime: json['start_time']?.toString(),
      endTime: json['end_time']?.toString(),
      dayOff: json['day_off']?.toString(),
      services: parsedServices,
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
      'bio': bio,
      'experience_years': experienceYears,
      'languages': languages,
      'specializations': specializations,
      'instagram': instagram,
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
    String? bio,
    int? experienceYears,
    List<String>? languages,
    String? specializations,
    String? instagram,
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
      bio: bio ?? this.bio,
      experienceYears: experienceYears ?? this.experienceYears,
      languages: languages ?? this.languages,
      specializations: specializations ?? this.specializations,
      instagram: instagram ?? this.instagram,
      workingDays: workingDays ?? this.workingDays,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      dayOff: dayOff ?? this.dayOff,
    );
  }
}
