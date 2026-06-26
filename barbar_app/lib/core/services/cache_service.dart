import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  static const String keySalonsCache = 'cached_salons_directory_list';

  Future<void> cacheSalonsList(List<Map<String, dynamic>> salons) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawJson = jsonEncode(salons);
      await prefs.setString(keySalonsCache, rawJson);
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>?> getCachedSalonsList() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawJson = prefs.getString(keySalonsCache);
      if (rawJson != null) {
        final decoded = jsonDecode(rawJson) as List;
        return decoded.map((e) => e as Map<String, dynamic>).toList();
      }
    } catch (_) {}
    return null;
  }

  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(keySalonsCache);
    } catch (_) {}
  }
}
