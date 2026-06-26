import '../../domain/repositories/directory_repository.dart';
import '../datasources/remote/directory_remote_datasource.dart';
import '../models/barber_model.dart';

class DirectoryRepositoryImpl implements DirectoryRepository {
  final DirectoryRemoteDataSource _remoteDataSource;

  static final List<BarberModel> _mockBarbers = [
    BarberModel(
      id: 'c0a80101-8fc2-11eb-8dcd-0242ac130003',
      shopName: 'Premium Barber Shop',
      shopDescription: 'Elite styling services & hot towel shaves',
      shopImage: 'https://images.unsplash.com/photo-1503951914875-452162b0f3f1?q=80&w=600',
      address: '123 Main Road, Indiranagar', city: 'Bengaluru',
      latitude: 12.9716, longitude: 77.5946,
      rating: 4.8, reviewCount: 142,
      isAvailable: true, currentQueueLength: 3, averageWaitTime: 45.0,
    ),
    BarberModel(
      id: 'd0b2c4d6-8fc2-11eb-8dcd-0242ac130004',
      shopName: 'The Golden Scissors',
      shopDescription: 'Luxury grooming, haircuts and beard shaping',
      shopImage: 'https://images.unsplash.com/photo-1621605815971-fbc98d665033?q=80&w=600',
      address: '45 Lavelle Road, Richmond Town', city: 'Bengaluru',
      latitude: 12.9725, longitude: 77.5950,
      rating: 4.9, reviewCount: 98,
      isAvailable: true, currentQueueLength: 1, averageWaitTime: 15.0,
    ),
    BarberModel(
      id: 'e1c3b2a1-8fc2-11eb-8dcd-0242ac130005',
      shopName: 'Onyx Grooming Lounge',
      shopDescription: 'Modern fades, styling, and charcoal facials',
      shopImage: 'https://images.unsplash.com/photo-1599351431202-1e0f0137899a?q=80&w=600',
      address: '80 Outer Ring Road, Koramangala', city: 'Bengaluru',
      latitude: 12.9352, longitude: 77.6244,
      rating: 4.6, reviewCount: 220,
      isAvailable: true, currentQueueLength: 5, averageWaitTime: 75.0,
    ),
  ];

  DirectoryRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<BarberModel>> getNearbyBarbers({
    required double latitude,
    required double longitude,
    int radius = 5000,
    String? search,
  }) async {
    try {
      return await _remoteDataSource.getNearbyBarbers(
        latitude: latitude,
        longitude: longitude,
        radius: radius,
        search: search,
      );
    } catch (_) {
      return List.from(_mockBarbers);
    }
  }
}
