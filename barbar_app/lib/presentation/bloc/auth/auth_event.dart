import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AppStarted extends AuthEvent {}

class SendOtpRequested extends AuthEvent {
  final String phone;

  const SendOtpRequested(this.phone);

  @override
  List<Object?> get props => [phone];
}

class VerifyOtpRequested extends AuthEvent {
  final String phone;
  final String otp;

  const VerifyOtpRequested({required this.phone, required this.otp});

  @override
  List<Object?> get props => [phone, otp];
}

class RegisterRequested extends AuthEvent {
  final String fullName;
  final String phone;
  final String password;
  final String role;
  final String? email;

  const RegisterRequested({
    required this.fullName,
    required this.phone,
    required this.password,
    required this.role,
    this.email,
  });

  @override
  List<Object?> get props => [fullName, phone, password, role, email];
}

class LogoutRequested extends AuthEvent {}

class UpdateProfileRequested extends AuthEvent {
  final Map<String, dynamic> data;

  const UpdateProfileRequested(this.data);

  @override
  List<Object?> get props => [data];
}
