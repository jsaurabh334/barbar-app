import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:barbar_app/data/models/banner_model.dart';
import 'package:barbar_app/domain/repositories/admin_repository.dart';

abstract class AdminBannersEvent extends Equatable {
  const AdminBannersEvent();
  @override
  List<Object?> get props => [];
}

class LoadBanners extends AdminBannersEvent {
  final int page;
  final String? position;
  final bool? isActive;
  const LoadBanners({this.page = 1, this.position, this.isActive});
  @override
  List<Object?> get props => [page, position, isActive];
}

class CreateBanner extends AdminBannersEvent {
  final Map<String, dynamic> data;
  const CreateBanner(this.data);
  @override
  List<Object?> get props => [data];
}

class UpdateBanner extends AdminBannersEvent {
  final String id;
  final Map<String, dynamic> data;
  const UpdateBanner(this.id, this.data);
  @override
  List<Object?> get props => [id, data];
}

class DeleteBanner extends AdminBannersEvent {
  final String id;
  const DeleteBanner(this.id);
  @override
  List<Object?> get props => [id];
}

class ToggleBannerActive extends AdminBannersEvent {
  final String id;
  const ToggleBannerActive(this.id);
  @override
  List<Object?> get props => [id];
}

abstract class AdminBannersState extends Equatable {
  const AdminBannersState();
  @override
  List<Object?> get props => [];
}

class AdminBannersInitial extends AdminBannersState {}

class AdminBannersLoading extends AdminBannersState {}

class AdminBannersLoaded extends AdminBannersState {
  final List<BannerModel> banners;
  final int currentPage;
  final bool hasReachedMax;
  final int total;
  const AdminBannersLoaded({required this.banners, this.currentPage = 1, this.hasReachedMax = false, this.total = 0});
  @override
  List<Object?> get props => [banners, currentPage, hasReachedMax, total];
}

class AdminBannersError extends AdminBannersState {
  final String message;
  const AdminBannersError(this.message);
  @override
  List<Object?> get props => [message];
}

class AdminBannerActionSuccess extends AdminBannersState {
  final String message;
  const AdminBannerActionSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

class AdminBannersBloc extends Bloc<AdminBannersEvent, AdminBannersState> {
  final AdminRepository _adminRepository;

  AdminBannersBloc({required AdminRepository adminRepository})
      : _adminRepository = adminRepository,
        super(AdminBannersInitial()) {
    on<LoadBanners>(_onLoadBanners);
    on<CreateBanner>(_onCreateBanner);
    on<UpdateBanner>(_onUpdateBanner);
    on<DeleteBanner>(_onDeleteBanner);
    on<ToggleBannerActive>(_onToggleBannerActive);
  }

  Future<void> _onLoadBanners(LoadBanners event, Emitter<AdminBannersState> emit) async {
    emit(AdminBannersLoading());
    try {
      final data = await _adminRepository.getAdminBanners(
        page: event.page,
        limit: 20,
        position: event.position,
        isActive: event.isActive,
      );
      final dynamic rawData = data['data'];
      final List<dynamic> items = rawData is List ? rawData : (rawData is Map ? (rawData['items'] ?? []) : []);
      final banners = items.map((j) => BannerModel.fromJson(j as Map<String, dynamic>)).toList();
      final total = (data['total_count'] as num?)?.toInt() ?? banners.length;
      emit(AdminBannersLoaded(
        banners: banners,
        currentPage: event.page,
        hasReachedMax: banners.length < 20 || (event.page * 20) >= total,
        total: total,
      ));
    } catch (e) {
      emit(AdminBannersError(e.toString()));
    }
  }

  Future<void> _onCreateBanner(CreateBanner event, Emitter<AdminBannersState> emit) async {
    try {
      await _adminRepository.createAdminBanner(event.data);
      emit(const AdminBannerActionSuccess('Banner created successfully'));
    } catch (e) {
      emit(AdminBannersError(e.toString()));
    }
  }

  Future<void> _onUpdateBanner(UpdateBanner event, Emitter<AdminBannersState> emit) async {
    try {
      await _adminRepository.updateAdminBanner(event.id, event.data);
      emit(const AdminBannerActionSuccess('Banner updated successfully'));
    } catch (e) {
      emit(AdminBannersError(e.toString()));
    }
  }

  Future<void> _onDeleteBanner(DeleteBanner event, Emitter<AdminBannersState> emit) async {
    try {
      await _adminRepository.deleteAdminBanner(event.id);
      emit(const AdminBannerActionSuccess('Banner deleted successfully'));
    } catch (e) {
      emit(AdminBannersError(e.toString()));
    }
  }

  Future<void> _onToggleBannerActive(ToggleBannerActive event, Emitter<AdminBannersState> emit) async {
    try {
      await _adminRepository.toggleAdminBannerActive(event.id);
      emit(const AdminBannerActionSuccess('Banner status toggled'));
    } catch (e) {
      emit(AdminBannersError(e.toString()));
    }
  }
}
