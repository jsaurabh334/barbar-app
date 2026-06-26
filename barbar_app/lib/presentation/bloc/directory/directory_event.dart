import 'package:equatable/equatable.dart';

abstract class DirectoryEvent extends Equatable {
  const DirectoryEvent();

  @override
  List<Object?> get props => [];
}

class FetchNearbyBarbers extends DirectoryEvent {
  final double latitude;
  final double longitude;
  final int radius;
  final String? search;

  const FetchNearbyBarbers({
    required this.latitude,
    required this.longitude,
    this.radius = 5000,
    this.search,
  });

  @override
  List<Object?> get props => [latitude, longitude, radius, search];
}

class UpdateBarberQueue extends DirectoryEvent {
  final String barberId;
  final int currentQueueLength;
  final double averageWaitTime;

  const UpdateBarberQueue({
    required this.barberId,
    required this.currentQueueLength,
    required this.averageWaitTime,
  });

  @override
  List<Object?> get props => [barberId, currentQueueLength, averageWaitTime];
}
