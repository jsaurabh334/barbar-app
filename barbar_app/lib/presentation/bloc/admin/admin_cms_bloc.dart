import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:barbar_app/data/models/cms_page_model.dart';
import 'package:barbar_app/domain/repositories/admin_repository.dart';

abstract class AdminCmsEvent extends Equatable {
  const AdminCmsEvent();
  @override
  List<Object?> get props => [];
}

class LoadCmsPages extends AdminCmsEvent {
  final int page;
  final String? type;
  final bool? isPublished;
  const LoadCmsPages({this.page = 1, this.type, this.isPublished});
  @override
  List<Object?> get props => [page, type, isPublished];
}

class CreateCmsPage extends AdminCmsEvent {
  final Map<String, dynamic> data;
  const CreateCmsPage(this.data);
  @override
  List<Object?> get props => [data];
}

class UpdateCmsPage extends AdminCmsEvent {
  final String id;
  final Map<String, dynamic> data;
  const UpdateCmsPage(this.id, this.data);
  @override
  List<Object?> get props => [id, data];
}

class DeleteCmsPage extends AdminCmsEvent {
  final String id;
  const DeleteCmsPage(this.id);
  @override
  List<Object?> get props => [id];
}

abstract class AdminCmsState extends Equatable {
  const AdminCmsState();
  @override
  List<Object?> get props => [];
}

class AdminCmsInitial extends AdminCmsState {}

class AdminCmsLoading extends AdminCmsState {}

class AdminCmsLoaded extends AdminCmsState {
  final List<CmsPageModel> pages;
  final int currentPage;
  final bool hasReachedMax;
  final int total;
  const AdminCmsLoaded({required this.pages, this.currentPage = 1, this.hasReachedMax = false, this.total = 0});
  @override
  List<Object?> get props => [pages, currentPage, hasReachedMax, total];
}

class AdminCmsError extends AdminCmsState {
  final String message;
  const AdminCmsError(this.message);
  @override
  List<Object?> get props => [message];
}

class AdminCmsActionSuccess extends AdminCmsState {
  final String message;
  const AdminCmsActionSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

class AdminCmsBloc extends Bloc<AdminCmsEvent, AdminCmsState> {
  final AdminRepository _adminRepository;

  AdminCmsBloc({required AdminRepository adminRepository})
      : _adminRepository = adminRepository,
        super(AdminCmsInitial()) {
    on<LoadCmsPages>(_onLoadCmsPages);
    on<CreateCmsPage>(_onCreateCmsPage);
    on<UpdateCmsPage>(_onUpdateCmsPage);
    on<DeleteCmsPage>(_onDeleteCmsPage);
  }

  Future<void> _onLoadCmsPages(LoadCmsPages event, Emitter<AdminCmsState> emit) async {
    emit(AdminCmsLoading());
    try {
      final data = await _adminRepository.getAdminCmsPages(
        page: event.page,
        limit: 20,
        type: event.type,
        isPublished: event.isPublished,
      );
      final dynamic rawData = data['data'];
      final List<dynamic> items = rawData is List ? rawData : (rawData is Map ? (rawData['items'] ?? []) : []);
      final pages = items.map((j) => CmsPageModel.fromJson(j as Map<String, dynamic>)).toList();
      final total = (data['total_count'] as num?)?.toInt() ?? pages.length;
      emit(AdminCmsLoaded(
        pages: pages,
        currentPage: event.page,
        hasReachedMax: pages.length < 20 || (event.page * 20) >= total,
        total: total,
      ));
    } catch (e) {
      emit(AdminCmsError(e.toString()));
    }
  }

  Future<void> _onCreateCmsPage(CreateCmsPage event, Emitter<AdminCmsState> emit) async {
    try {
      await _adminRepository.createAdminCmsPage(event.data);
      emit(const AdminCmsActionSuccess('Page created'));
    } catch (e) {
      emit(AdminCmsError(e.toString()));
    }
  }

  Future<void> _onUpdateCmsPage(UpdateCmsPage event, Emitter<AdminCmsState> emit) async {
    try {
      await _adminRepository.updateAdminCmsPage(event.id, event.data);
      emit(const AdminCmsActionSuccess('Page updated'));
    } catch (e) {
      emit(AdminCmsError(e.toString()));
    }
  }

  Future<void> _onDeleteCmsPage(DeleteCmsPage event, Emitter<AdminCmsState> emit) async {
    try {
      await _adminRepository.deleteAdminCmsPage(event.id);
      emit(const AdminCmsActionSuccess('Page deleted'));
    } catch (e) {
      emit(AdminCmsError(e.toString()));
    }
  }
}
