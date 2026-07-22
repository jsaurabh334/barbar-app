import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:barbar_app/domain/repositories/admin_repository.dart';

abstract class AdminPromotionsEvent extends Equatable {
  const AdminPromotionsEvent();
  @override
  List<Object?> get props => [];
}

class LoadCoupons extends AdminPromotionsEvent {
  final int page;
  final bool? isActive;
  const LoadCoupons({this.page = 1, this.isActive});
  @override
  List<Object?> get props => [page, isActive];
}

class CreateCoupon extends AdminPromotionsEvent {
  final Map<String, dynamic> data;
  const CreateCoupon(this.data);
  @override
  List<Object?> get props => [data];
}

class UpdateCoupon extends AdminPromotionsEvent {
  final String id;
  final Map<String, dynamic> data;
  const UpdateCoupon(this.id, this.data);
  @override
  List<Object?> get props => [id, data];
}

class DeleteCoupon extends AdminPromotionsEvent {
  final String id;
  const DeleteCoupon(this.id);
  @override
  List<Object?> get props => [id];
}

class LoadFeaturedListings extends AdminPromotionsEvent {
  final int page;
  final String? status;
  const LoadFeaturedListings({this.page = 1, this.status});
  @override
  List<Object?> get props => [page, status];
}

class CreateFeaturedListing extends AdminPromotionsEvent {
  final Map<String, dynamic> data;
  const CreateFeaturedListing(this.data);
  @override
  List<Object?> get props => [data];
}

class DeleteFeaturedListing extends AdminPromotionsEvent {
  final String id;
  const DeleteFeaturedListing(this.id);
  @override
  List<Object?> get props => [id];
}

class LoadNotificationTemplates extends AdminPromotionsEvent {
  final int page;
  final String? type;
  final String? channel;
  final bool? isActive;
  const LoadNotificationTemplates({this.page = 1, this.type, this.channel, this.isActive});
  @override
  List<Object?> get props => [page, type, channel, isActive];
}

class GetNotificationTemplateDetail extends AdminPromotionsEvent {
  final String id;
  const GetNotificationTemplateDetail(this.id);
  @override
  List<Object?> get props => [id];
}

class CreateNotificationTemplate extends AdminPromotionsEvent {
  final Map<String, dynamic> data;
  const CreateNotificationTemplate(this.data);
  @override
  List<Object?> get props => [data];
}

class UpdateNotificationTemplate extends AdminPromotionsEvent {
  final String id;
  final Map<String, dynamic> data;
  const UpdateNotificationTemplate(this.id, this.data);
  @override
  List<Object?> get props => [id, data];
}

class DeleteNotificationTemplate extends AdminPromotionsEvent {
  final String id;
  const DeleteNotificationTemplate(this.id);
  @override
  List<Object?> get props => [id];
}

abstract class AdminPromotionsState extends Equatable {
  const AdminPromotionsState();
  @override
  List<Object?> get props => [];
}

class AdminPromotionsInitial extends AdminPromotionsState {}
class AdminPromotionsLoading extends AdminPromotionsState {}

class CouponsLoaded extends AdminPromotionsState {
  final List<dynamic> coupons;
  final int currentPage;
  final bool hasReachedMax;
  const CouponsLoaded({required this.coupons, this.currentPage = 1, this.hasReachedMax = false});
  @override
  List<Object?> get props => [coupons, currentPage, hasReachedMax];
}

class FeaturedListingsLoaded extends AdminPromotionsState {
  final List<dynamic> listings;
  final int currentPage;
  final bool hasReachedMax;
  const FeaturedListingsLoaded({required this.listings, this.currentPage = 1, this.hasReachedMax = false});
  @override
  List<Object?> get props => [listings, currentPage, hasReachedMax];
}

class NotificationTemplatesLoaded extends AdminPromotionsState {
  final List<dynamic> templates;
  final int currentPage;
  final bool hasReachedMax;
  const NotificationTemplatesLoaded({required this.templates, this.currentPage = 1, this.hasReachedMax = false});
  @override
  List<Object?> get props => [templates, currentPage, hasReachedMax];
}

class NotificationTemplateDetailLoaded extends AdminPromotionsState {
  final Map<String, dynamic> template;
  const NotificationTemplateDetailLoaded(this.template);
  @override
  List<Object?> get props => [template];
}

class AdminPromotionsError extends AdminPromotionsState {
  final String message;
  const AdminPromotionsError(this.message);
  @override
  List<Object?> get props => [message];
}

class AdminPromotionsActionSuccess extends AdminPromotionsState {
  final String message;
  const AdminPromotionsActionSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

class AdminPromotionsBloc extends Bloc<AdminPromotionsEvent, AdminPromotionsState> {
  final AdminRepository adminRepository;

  AdminPromotionsBloc({required this.adminRepository}) : super(AdminPromotionsInitial()) {
    on<LoadCoupons>(_onLoadCoupons);
    on<CreateCoupon>(_onCreateCoupon);
    on<UpdateCoupon>(_onUpdateCoupon);
    on<DeleteCoupon>(_onDeleteCoupon);
    on<LoadFeaturedListings>(_onLoadFeaturedListings);
    on<CreateFeaturedListing>(_onCreateFeaturedListing);
    on<DeleteFeaturedListing>(_onDeleteFeaturedListing);
    on<LoadNotificationTemplates>(_onLoadNotificationTemplates);
    on<GetNotificationTemplateDetail>(_onGetNotificationTemplateDetail);
    on<CreateNotificationTemplate>(_onCreateNotificationTemplate);
    on<UpdateNotificationTemplate>(_onUpdateNotificationTemplate);
    on<DeleteNotificationTemplate>(_onDeleteNotificationTemplate);
  }

  Future<void> _onLoadCoupons(LoadCoupons event, Emitter<AdminPromotionsState> emit) async {
    if (event.page == 1) emit(AdminPromotionsLoading());
    try {
      final result = await adminRepository.getAdminCoupons(page: event.page, isActive: event.isActive);
      final List<dynamic> rawData = (result['data'] is List) ? result['data'] : (result['data']?['data'] ?? []);
      if (state is CouponsLoaded && event.page > 1) {
        final cur = state as CouponsLoaded;
        emit(CouponsLoaded(coupons: cur.coupons + rawData, currentPage: event.page, hasReachedMax: rawData.isEmpty));
      } else {
        emit(CouponsLoaded(coupons: rawData, currentPage: event.page, hasReachedMax: rawData.isEmpty));
      }
    } catch (e) {
      emit(AdminPromotionsError(e.toString()));
    }
  }

  Future<void> _onCreateCoupon(CreateCoupon event, Emitter<AdminPromotionsState> emit) async {
    try {
      await adminRepository.createAdminCoupon(event.data);
      emit(const AdminPromotionsActionSuccess('Coupon created'));
    } catch (e) {
      emit(AdminPromotionsError(e.toString()));
    }
  }

  Future<void> _onUpdateCoupon(UpdateCoupon event, Emitter<AdminPromotionsState> emit) async {
    try {
      await adminRepository.updateAdminCoupon(event.id, event.data);
      emit(const AdminPromotionsActionSuccess('Coupon updated'));
    } catch (e) {
      emit(AdminPromotionsError(e.toString()));
    }
  }

  Future<void> _onDeleteCoupon(DeleteCoupon event, Emitter<AdminPromotionsState> emit) async {
    try {
      await adminRepository.deleteAdminCoupon(event.id);
      emit(const AdminPromotionsActionSuccess('Coupon deleted'));
    } catch (e) {
      emit(AdminPromotionsError(e.toString()));
    }
  }

  Future<void> _onLoadFeaturedListings(LoadFeaturedListings event, Emitter<AdminPromotionsState> emit) async {
    if (event.page == 1) emit(AdminPromotionsLoading());
    try {
      final result = await adminRepository.getAdminFeaturedListings(page: event.page, status: event.status);
      final List<dynamic> rawData = (result['data'] is List) ? result['data'] : (result['data']?['data'] ?? []);
      if (state is FeaturedListingsLoaded && event.page > 1) {
        final cur = state as FeaturedListingsLoaded;
        emit(FeaturedListingsLoaded(listings: cur.listings + rawData, currentPage: event.page, hasReachedMax: rawData.isEmpty));
      } else {
        emit(FeaturedListingsLoaded(listings: rawData, currentPage: event.page, hasReachedMax: rawData.isEmpty));
      }
    } catch (e) {
      emit(AdminPromotionsError(e.toString()));
    }
  }

  Future<void> _onCreateFeaturedListing(CreateFeaturedListing event, Emitter<AdminPromotionsState> emit) async {
    try {
      await adminRepository.createAdminFeaturedListing(event.data);
      emit(const AdminPromotionsActionSuccess('Featured listing created'));
    } catch (e) {
      emit(AdminPromotionsError(e.toString()));
    }
  }

  Future<void> _onDeleteFeaturedListing(DeleteFeaturedListing event, Emitter<AdminPromotionsState> emit) async {
    try {
      await adminRepository.deleteAdminFeaturedListing(event.id);
      emit(const AdminPromotionsActionSuccess('Featured listing deleted'));
    } catch (e) {
      emit(AdminPromotionsError(e.toString()));
    }
  }

  Future<void> _onLoadNotificationTemplates(LoadNotificationTemplates event, Emitter<AdminPromotionsState> emit) async {
    if (event.page == 1) emit(AdminPromotionsLoading());
    try {
      final result = await adminRepository.getAdminNotificationTemplates(page: event.page, type: event.type, channel: event.channel, isActive: event.isActive);
      final List<dynamic> rawData = (result['data'] is List) ? result['data'] : (result['data']?['data'] ?? []);
      if (state is NotificationTemplatesLoaded && event.page > 1) {
        final cur = state as NotificationTemplatesLoaded;
        emit(NotificationTemplatesLoaded(templates: cur.templates + rawData, currentPage: event.page, hasReachedMax: rawData.isEmpty));
      } else {
        emit(NotificationTemplatesLoaded(templates: rawData, currentPage: event.page, hasReachedMax: rawData.isEmpty));
      }
    } catch (e) {
      emit(AdminPromotionsError(e.toString()));
    }
  }

  Future<void> _onGetNotificationTemplateDetail(GetNotificationTemplateDetail event, Emitter<AdminPromotionsState> emit) async {
    try {
      final data = await adminRepository.getAdminNotificationTemplateDetail(event.id);
      emit(NotificationTemplateDetailLoaded(data));
    } catch (e) {
      emit(AdminPromotionsError(e.toString()));
    }
  }

  Future<void> _onCreateNotificationTemplate(CreateNotificationTemplate event, Emitter<AdminPromotionsState> emit) async {
    try {
      await adminRepository.createAdminNotificationTemplate(event.data);
      emit(const AdminPromotionsActionSuccess('Notification template created'));
    } catch (e) {
      emit(AdminPromotionsError(e.toString()));
    }
  }

  Future<void> _onUpdateNotificationTemplate(UpdateNotificationTemplate event, Emitter<AdminPromotionsState> emit) async {
    try {
      await adminRepository.updateAdminNotificationTemplate(event.id, event.data);
      emit(const AdminPromotionsActionSuccess('Notification template updated'));
    } catch (e) {
      emit(AdminPromotionsError(e.toString()));
    }
  }

  Future<void> _onDeleteNotificationTemplate(DeleteNotificationTemplate event, Emitter<AdminPromotionsState> emit) async {
    try {
      await adminRepository.deleteAdminNotificationTemplate(event.id);
      emit(const AdminPromotionsActionSuccess('Notification template deleted'));
    } catch (e) {
      emit(AdminPromotionsError(e.toString()));
    }
  }
}
