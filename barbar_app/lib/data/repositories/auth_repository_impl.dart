import '../../domain/repositories/auth_repository.dart';
import '../datasources/local/auth_local_datasource.dart';
import '../datasources/remote/auth_remote_datasource.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;

  AuthRepositoryImpl(this._remoteDataSource, this._localDataSource);

  @override
  Future<void> register({
    required String fullName,
    required String phone,
    required String password,
    required String role,
    String? email,
  }) async {
    final data = await _remoteDataSource.register(
      fullName: fullName,
      phone: phone,
      password: password,
      role: role,
      email: email,
    );
    
    // Save tokens and user details
    final tokens = data['tokens'];
    final user = data['user'];
    
    await _localDataSource.saveAccessToken(tokens['access_token'] as String);
    await _localDataSource.saveRefreshToken(tokens['refresh_token'] as String);
    await _localDataSource.saveUserData(user as Map<String, dynamic>);
  }

  @override
  Future<bool> sendOtp(String phone) async {
    return await _remoteDataSource.sendOtp(phone);
  }

  @override
  Future<UserModel> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    final data = await _remoteDataSource.verifyOtp(phone: phone, otp: otp);
    
    // Save tokens and user details
    final tokens = data['tokens'];
    final userMap = data['user'] as Map<String, dynamic>;
    
    await _localDataSource.saveAccessToken(tokens['access_token'] as String);
    await _localDataSource.saveRefreshToken(tokens['refresh_token'] as String);
    
    // Fill required user schema properties from login response context if missing
    if (!userMap.containsKey('phone') || userMap['phone'] == null) userMap['phone'] = phone;
    if (!userMap.containsKey('full_name') || userMap['full_name'] == null) userMap['full_name'] = 'Client';
    if (!userMap.containsKey('role') || userMap['role'] == null) userMap['role'] = 'customer';
    if (!userMap.containsKey('status') || userMap['status'] == null) userMap['status'] = 'active';
    if (!userMap.containsKey('otp_verified') || userMap['otp_verified'] == null) userMap['otp_verified'] = true;
    if (!userMap.containsKey('language_pref') || userMap['language_pref'] == null) userMap['language_pref'] = 'en';

    await _localDataSource.saveUserData(userMap);
    return UserModel.fromJson(userMap);
  }

  @override
  Future<UserModel?> getCachedUser() async {
    final userMap = await _localDataSource.getUserData();
    if (userMap != null) {
      return UserModel.fromJson(userMap);
    }
    return null;
  }

  @override
  Future<void> logout() async {
    await _remoteDataSource.logout();
    await _localDataSource.clearSession();
  }

  @override
  Future<bool> isLoggedIn() async {
    final token = await _localDataSource.getAccessToken();
    return token != null;
  }

  @override
  Future<UserModel> updateProfile(Map<String, dynamic> data) async {
    final updatedUser = await _remoteDataSource.updateProfile(data);
    await _localDataSource.saveUserData(updatedUser.toJson());
    return updatedUser;
  }

  @override
  Future<String> uploadImage(String filePath) async {
    return await _remoteDataSource.uploadImage(filePath);
  }
}
