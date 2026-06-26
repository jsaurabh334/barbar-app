import '../../data/models/barber_model.dart';

abstract class DirectoryRepository {
  Future<List<BarberModel>> getNearbyBarbers({
    required double latitude,
    required double longitude,
    int radius = 5000,
    String? search,
  });
}
