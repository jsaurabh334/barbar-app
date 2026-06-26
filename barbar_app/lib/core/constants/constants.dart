import 'dart:io';

class AppConstants {
  // Session / Storage keys
  static const String keyAccessToken = 'access_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyUserData = 'user_data';
  
  // Default connection timeouts
  static const int connectTimeoutMs = 15000;
  static const int receiveTimeoutMs = 15000;
}

class AppConfig {
  // Toggle this to switch between local development and production
  static const bool isProduction = false;

  static String get apiBaseUrl {
    if (isProduction) {
      return 'https://api.barbar.app/api/v1/';
    } else {
      // 10.0.2.2 is the localhost alias for Android Emulator.
      // Use 'http://localhost:8080/api/v1' for iOS Simulator or macOS app.
      final host = Platform.isAndroid ? '10.0.2.2' : 'localhost';
      return 'http://$host:8080/api/v1/';
    }
  }
  
  static String get wsBaseUrl {
    if (isProduction) {
      return 'wss://api.barbar.app/ws';
    } else {
      final host = Platform.isAndroid ? '10.0.2.2' : 'localhost';
      return 'ws://$host:8080/ws';
    }
  }
}
