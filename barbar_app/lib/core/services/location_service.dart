import 'dart:async';
import 'package:geolocator/geolocator.dart';

enum LocationError { denied, deniedForever, gpsDisabled, timeout, unknown }

class LocationResult {
  final double latitude;
  final double longitude;
  final LocationError? error;

  LocationResult(this.latitude, this.longitude, {this.error});

  bool get hasError => error != null;
}

class LocationService {
  static const double defaultLatitude = 12.9716;
  static const double defaultLongitude = 77.5946;

  Future<Position?> getCurrentPosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }

      if (permission == LocationPermission.deniedForever) return null;

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  Future<LocationResult> getCoordinates() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return LocationResult(defaultLatitude, defaultLongitude, error: LocationError.gpsDisabled);
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return LocationResult(defaultLatitude, defaultLongitude, error: LocationError.denied);
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return LocationResult(defaultLatitude, defaultLongitude, error: LocationError.deniedForever);
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      );

      return LocationResult(position.latitude, position.longitude);
    } on TimeoutException {
      return LocationResult(defaultLatitude, defaultLongitude, error: LocationError.timeout);
    } catch (_) {
      return LocationResult(defaultLatitude, defaultLongitude, error: LocationError.unknown);
    }
  }

  Future<bool> openLocationSettings() async {
    return Geolocator.openLocationSettings();
  }

  Future<bool> openAppSettings() async {
    return Geolocator.openAppSettings();
  }
}
