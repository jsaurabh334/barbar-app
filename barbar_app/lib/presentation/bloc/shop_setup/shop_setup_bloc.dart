import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:barbar_app/domain/repositories/barber_repository.dart';
import 'package:barbar_app/domain/repositories/directory_repository.dart';
import 'package:barbar_app/data/models/category_model.dart';
import 'package:equatable/equatable.dart';

abstract class ShopSetupEvent extends Equatable {
  const ShopSetupEvent();
  @override
  List<Object?> get props => [];
}

class LoadCategories extends ShopSetupEvent {}

class SubmitShop extends ShopSetupEvent {
  final Map<String, dynamic> data;
  const SubmitShop(this.data);
  @override
  List<Object?> get props => [data];
}

abstract class ShopSetupState extends Equatable {
  const ShopSetupState();
  @override
  List<Object?> get props => [];
}

class ShopSetupInitial extends ShopSetupState {}

class ShopSetupLoading extends ShopSetupState {}

class CategoriesLoaded extends ShopSetupState {
  final List<CategoryModel> categories;
  const CategoriesLoaded(this.categories);
  @override
  List<Object?> get props => [categories];
}

class ShopSetupSubmitting extends ShopSetupState {}

class ShopSetupSuccess extends ShopSetupState {
  final Map<String, dynamic> shop;
  const ShopSetupSuccess(this.shop);
  @override
  List<Object?> get props => [shop];
}

class ShopSetupFailure extends ShopSetupState {
  final String error;
  const ShopSetupFailure(this.error);
  @override
  List<Object?> get props => [error];
}

class ShopSetupBloc extends Bloc<ShopSetupEvent, ShopSetupState> {
  final BarberRepository _barberRepository;
  final DirectoryRepository _directoryRepository;

  ShopSetupBloc({
    required BarberRepository barberRepository,
    required DirectoryRepository directoryRepository,
  })  : _barberRepository = barberRepository,
        _directoryRepository = directoryRepository,
        super(ShopSetupInitial()) {
    on<LoadCategories>(_onLoadCategories);
    on<SubmitShop>(_onSubmitShop);
  }

  Future<void> _onLoadCategories(LoadCategories event, Emitter<ShopSetupState> emit) async {
    emit(ShopSetupLoading());
    try {
      final categories = await _directoryRepository.getCategories();
      emit(CategoriesLoaded(categories));
    } catch (e) {
      emit(ShopSetupFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onSubmitShop(SubmitShop event, Emitter<ShopSetupState> emit) async {
    emit(ShopSetupSubmitting());
    try {
      final shop = await _barberRepository.registerBarber(event.data);
      emit(ShopSetupSuccess(shop));
    } catch (e) {
      emit(ShopSetupFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
