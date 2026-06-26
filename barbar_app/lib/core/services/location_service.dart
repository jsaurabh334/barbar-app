import 'package:geolocator/geolocator.dart';

class LocationService {
  // Default fallback coords (Bengaluru, India)
  static const double defaultLatitude = 12.9716;
  static const double defaultLongitude = 77.5946;

  Future<Position?> getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    try {
      // Test if location services are enabled.
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      // When we reach here, permissions are granted and we can
      // continue accessing the position of the device.
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

  Future<Map<String, double>> getCoordinates() async {
    final position = await getCurrentPosition();
    if (position != null) {
      return {
        'latitude': position.latitude,
        'longitude': position.longitude,
      };
    }
    return {
      'latitude': defaultLatitude,
      'longitude': defaultLongitude,
    };
  }
}
