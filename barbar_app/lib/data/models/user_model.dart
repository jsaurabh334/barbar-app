class UserModel {
  final String id;
  final String? email;
  final String phone;
  final String fullName;
  final String? avatar;
  final String role;
  final String status;
  final bool otpVerified;
  final String languagePref;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastLoginAt;

  UserModel({
    required this.id,
    this.email,
    required this.phone,
    required this.fullName,
    this.avatar,
    required this.role,
    required this.status,
    required this.otpVerified,
    required this.languagePref,
    this.createdAt,
    this.updatedAt,
    this.lastLoginAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String,
      fullName: (json['full_name'] as String?) ?? 'User',
      avatar: json['avatar'] as String?,
      role: (json['role'] as String?) ?? 'customer',
      status: (json['status'] as String?) ?? 'active',
      otpVerified: (json['otp_verified'] as bool?) ?? false,
      languagePref: (json['language_pref'] as String?) ?? 'en',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']) : null,
      lastLoginAt: json['last_login_at'] != null ? DateTime.tryParse(json['last_login_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'phone': phone,
      'full_name': fullName,
      'avatar': avatar,
      'role': role,
      'status': status,
      'otp_verified': otpVerified,
      'language_pref': languagePref,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      if (lastLoginAt != null) 'last_login_at': lastLoginAt!.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? phone,
    String? fullName,
    String? avatar,
    String? role,
    String? status,
    bool? otpVerified,
    String? languagePref,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLoginAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      fullName: fullName ?? this.fullName,
      avatar: avatar ?? this.avatar,
      role: role ?? this.role,
      status: status ?? this.status,
      otpVerified: otpVerified ?? this.otpVerified,
      languagePref: languagePref ?? this.languagePref,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }
}
