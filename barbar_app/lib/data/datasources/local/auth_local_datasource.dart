import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/constants/constants.dart';

class AuthLocalDataSource {
  final FlutterSecureStorage _secureStorage;

  // Memory fallback to handle Keychain sharing / simulator entitlement errors (-34018) gracefully
  static final Map<String, String> _memoryFallback = {};

  AuthLocalDataSource({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage(
          iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
          mOptions: MacOsOptions(accessibility: KeychainAccessibility.first_unlock),
        );

  Future<void> saveAccessToken(String token) async {
    try {
      await _secureStorage.write(key: AppConstants.keyAccessToken, value: token);
    } catch (_) {
      _memoryFallback[AppConstants.keyAccessToken] = token;
    }
  }

  Future<String?> getAccessToken() async {
    try {
      return await _secureStorage.read(key: AppConstants.keyAccessToken);
    } catch (_) {
      return _memoryFallback[AppConstants.keyAccessToken];
    }
  }

  Future<void> saveRefreshToken(String token) async {
    try {
      await _secureStorage.write(key: AppConstants.keyRefreshToken, value: token);
    } catch (_) {
      _memoryFallback[AppConstants.keyRefreshToken] = token;
    }
  }

  Future<String?> getRefreshToken() async {
    try {
      return await _secureStorage.read(key: AppConstants.keyRefreshToken);
    } catch (_) {
      return _memoryFallback[AppConstants.keyRefreshToken];
    }
  }

  Future<void> saveUserData(Map<String, dynamic> userMap) async {
    final rawJson = jsonEncode(userMap);
    try {
      await _secureStorage.write(key: AppConstants.keyUserData, value: rawJson);
    } catch (_) {
      _memoryFallback[AppConstants.keyUserData] = rawJson;
    }
  }

  Future<Map<String, dynamic>?> getUserData() async {
    String? rawJson;
    try {
      rawJson = await _secureStorage.read(key: AppConstants.keyUserData);
    } catch (_) {
      rawJson = _memoryFallback[AppConstants.keyUserData];
    }
    
    if (rawJson != null) {
      try {
        return jsonDecode(rawJson) as Map<String, dynamic>;
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  Future<void> clearSession() async {
    try {
      await _secureStorage.delete(key: AppConstants.keyAccessToken);
      await _secureStorage.delete(key: AppConstants.keyRefreshToken);
      await _secureStorage.delete(key: AppConstants.keyUserData);
    } catch (_) {
      _memoryFallback.clear();
    }
  }
}
