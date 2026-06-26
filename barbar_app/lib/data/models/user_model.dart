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
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String,
      fullName: json['full_name'] as String,
      avatar: json['avatar'] as String?,
      role: json['role'] as String,
      status: json['status'] as String,
      otpVerified: (json['otp_verified'] as bool?) ?? false,
      languagePref: (json['language_pref'] as String?) ?? 'en',
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
    );
  }
}
