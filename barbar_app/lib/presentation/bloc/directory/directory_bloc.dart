import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/category_model.dart';
import '../../../domain/repositories/directory_repository.dart';
import 'directory_event.dart';
import 'directory_state.dart';

class DirectoryBloc extends Bloc<DirectoryEvent, DirectoryState> {
  final DirectoryRepository _directoryRepository;

  DirectoryBloc(this._directoryRepository) : super(DirectoryInitial()) {
    on<FetchNearbyBarbers>(_onFetchNearbyBarbers);
    on<UpdateBarberQueue>(_onUpdateBarberQueue);
    on<FetchCategories>(_onFetchCategories);
    on<SetSelectedCategory>(_onSetSelectedCategory);
  }

  Future<void> _onFetchNearbyBarbers(
    FetchNearbyBarbers event,
    Emitter<DirectoryState> emit,
  ) async {
    List<CategoryModel> prevCategories = [];
    CategoryModel? prevSelectedCategory;
    if (state is DirectoryLoaded) {
      prevCategories = (state as DirectoryLoaded).categories;
      prevSelectedCategory = (state as DirectoryLoaded).selectedCategory;
    }

    emit(DirectoryLoading());
    try {
      final barbers = await _directoryRepository.getNearbyBarbers(
        latitude: event.latitude,
        longitude: event.longitude,
        radius: event.radius,
        search: event.search,
        minRating: event.minRating,
        openNow: event.openNow,
        categoryId: event.categoryId,
      );
      emit(DirectoryLoaded(barbers, categories: prevCategories, selectedCategory: prevSelectedCategory));
    } catch (e) {
      emit(DirectoryFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  void _onUpdateBarberQueue(UpdateBarberQueue event, Emitter<DirectoryState> emit) {
    if (state is DirectoryLoaded) {
      final s = state as DirectoryLoaded;
      final updatedList = s.barbers.map((barber) {
        if (barber.id == event.barberId) {
          return barber.copyWith(
            currentQueueLength: event.currentQueueLength,
            averageWaitTime: event.averageWaitTime,
          );
        }
        return barber;
      }).toList();
      emit(DirectoryLoaded(updatedList,
          categories: s.categories,
          selectedCategory: s.selectedCategory,
          isCategoriesLoading: s.isCategoriesLoading,
          categoriesError: s.categoriesError));
    }
  }

  Future<void> _onFetchCategories(
    FetchCategories event,
    Emitter<DirectoryState> emit,
  ) async {
    if (state is DirectoryLoaded) {
      final s = state as DirectoryLoaded;
      emit(DirectoryLoaded(s.barbers,
          categories: s.categories,
          selectedCategory: s.selectedCategory,
          isCategoriesLoading: true));
    } else {
      emit(DirectoryLoaded([], isCategoriesLoading: true));
    }
    try {
      final categories = await _directoryRepository.getCategories();
      if (state is DirectoryLoaded) {
        final s = state as DirectoryLoaded;
        emit(DirectoryLoaded(s.barbers,
            categories: categories,
            selectedCategory: s.selectedCategory,
            isCategoriesLoading: false));
      } else {
        emit(DirectoryLoaded([], categories: categories, isCategoriesLoading: false));
      }
    } catch (e) {
      if (state is DirectoryLoaded) {
        final s = state as DirectoryLoaded;
        emit(DirectoryLoaded(s.barbers,
            categories: s.categories,
            selectedCategory: s.selectedCategory,
            isCategoriesLoading: false,
            categoriesError: e.toString().replaceAll('Exception: ', '')));
      }
    }
  }

  void _onSetSelectedCategory(SetSelectedCategory event, Emitter<DirectoryState> emit) {
    if (state is DirectoryLoaded) {
      final s = state as DirectoryLoaded;
      emit(DirectoryLoaded(s.barbers,
          categories: s.categories,
          selectedCategory: event.category,
          isCategoriesLoading: s.isCategoriesLoading,
          categoriesError: s.categoriesError));
    }
  }

  List<CategoryModel> _extractCategories() {
    if (state is DirectoryLoaded) {
      return (state as DirectoryLoaded).categories;
    }
    return [];
  }
}
