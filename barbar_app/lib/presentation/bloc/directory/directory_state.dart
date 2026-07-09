import 'package:equatable/equatable.dart';
import '../../../data/models/barber_model.dart';
import '../../../data/models/category_model.dart';

abstract class DirectoryState extends Equatable {
  const DirectoryState();

  @override
  List<Object?> get props => [];
}

class DirectoryInitial extends DirectoryState {}

class DirectoryLoading extends DirectoryState {}

class DirectoryLoaded extends DirectoryState {
  final List<BarberModel> barbers;
  final List<CategoryModel> categories;
  final CategoryModel? selectedCategory;
  final bool isCategoriesLoading;
  final String? categoriesError;

  const DirectoryLoaded(this.barbers, {
    this.categories = const [],
    this.selectedCategory,
    this.isCategoriesLoading = false,
    this.categoriesError,
  });

  @override
  List<Object?> get props => [barbers, categories, selectedCategory, isCategoriesLoading, categoriesError];
}

class DirectoryFailure extends DirectoryState {
  final String error;

  const DirectoryFailure(this.error);

  @override
  List<Object?> get props => [error];
}
