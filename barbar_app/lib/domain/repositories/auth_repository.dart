import '../../data/models/user_model.dart';

abstract class AuthRepository {
  Future<void> register({
    required String fullName,
    required String phone,
    required String password,
    required String role,
    String? email,
  });

  Future<bool> sendOtp(String phone);

  Future<UserModel> verifyOtp({
    required String phone,
    required String otp,
  });

  Future<UserModel?> getCachedUser();

  Future<void> logout();

  Future<bool> isLoggedIn();
}
