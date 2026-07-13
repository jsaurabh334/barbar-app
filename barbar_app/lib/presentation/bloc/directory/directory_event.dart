import 'package:equatable/equatable.dart';
import '../../../data/models/category_model.dart';

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
  final double? minRating;
  final bool? openNow;
  final String? categoryId;

  const FetchNearbyBarbers({
    required this.latitude,
    required this.longitude,
    this.radius = 50000000,
    this.search,
    this.minRating,
    this.openNow,
    this.categoryId,
  });

  @override
  List<Object?> get props => [latitude, longitude, radius, search, minRating, openNow, categoryId];
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

class FetchCategories extends DirectoryEvent {
  const FetchCategories();

  @override
  List<Object?> get props => [];
}

class SetSelectedCategory extends DirectoryEvent {
  final CategoryModel? category;

  const SetSelectedCategory(this.category);

  @override
  List<Object?> get props => [category];
}
