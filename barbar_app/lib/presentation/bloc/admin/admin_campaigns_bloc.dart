import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:barbar_app/data/models/campaign_model.dart';
import 'package:barbar_app/domain/repositories/admin_repository.dart';

abstract class AdminCampaignsEvent extends Equatable {
  const AdminCampaignsEvent();
  @override
  List<Object?> get props => [];
}

class LoadCampaigns extends AdminCampaignsEvent {
  final int page;
  final String? status;
  final String? targetType;
  const LoadCampaigns({this.page = 1, this.status, this.targetType});
  @override
  List<Object?> get props => [page, status, targetType];
}

class CreateCampaign extends AdminCampaignsEvent {
  final Map<String, dynamic> data;
  const CreateCampaign(this.data);
  @override
  List<Object?> get props => [data];
}

class UpdateCampaign extends AdminCampaignsEvent {
  final String id;
  final Map<String, dynamic> data;
  const UpdateCampaign(this.id, this.data);
  @override
  List<Object?> get props => [id, data];
}

class DeleteCampaign extends AdminCampaignsEvent {
  final String id;
  const DeleteCampaign(this.id);
  @override
  List<Object?> get props => [id];
}

class SendCampaign extends AdminCampaignsEvent {
  final String id;
  const SendCampaign(this.id);
  @override
  List<Object?> get props => [id];
}

abstract class AdminCampaignsState extends Equatable {
  const AdminCampaignsState();
  @override
  List<Object?> get props => [];
}

class AdminCampaignsInitial extends AdminCampaignsState {}

class AdminCampaignsLoading extends AdminCampaignsState {}

class AdminCampaignsLoaded extends AdminCampaignsState {
  final List<CampaignModel> campaigns;
  final int currentPage;
  final bool hasReachedMax;
  final int total;
  const AdminCampaignsLoaded({required this.campaigns, this.currentPage = 1, this.hasReachedMax = false, this.total = 0});
  @override
  List<Object?> get props => [campaigns, currentPage, hasReachedMax, total];
}

class AdminCampaignsError extends AdminCampaignsState {
  final String message;
  const AdminCampaignsError(this.message);
  @override
  List<Object?> get props => [message];
}

class AdminCampaignActionSuccess extends AdminCampaignsState {
  final String message;
  const AdminCampaignActionSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

class AdminCampaignsBloc extends Bloc<AdminCampaignsEvent, AdminCampaignsState> {
  final AdminRepository _adminRepository;

  AdminCampaignsBloc({required AdminRepository adminRepository})
      : _adminRepository = adminRepository,
        super(AdminCampaignsInitial()) {
    on<LoadCampaigns>(_onLoadCampaigns);
    on<CreateCampaign>(_onCreateCampaign);
    on<UpdateCampaign>(_onUpdateCampaign);
    on<DeleteCampaign>(_onDeleteCampaign);
    on<SendCampaign>(_onSendCampaign);
  }

  Future<void> _onLoadCampaigns(LoadCampaigns event, Emitter<AdminCampaignsState> emit) async {
    emit(AdminCampaignsLoading());
    try {
      final data = await _adminRepository.getAdminCampaigns(
        page: event.page,
        limit: 20,
        status: event.status,
        targetType: event.targetType,
      );
      final dynamic rawData = data['data'];
      final List<dynamic> items = rawData is List ? rawData : (rawData is Map ? (rawData['items'] ?? []) : []);
      final campaigns = items.map((j) => CampaignModel.fromJson(j as Map<String, dynamic>)).toList();
      final total = (data['total_count'] as num?)?.toInt() ?? campaigns.length;
      emit(AdminCampaignsLoaded(
        campaigns: campaigns,
        currentPage: event.page,
        hasReachedMax: campaigns.length < 20 || (event.page * 20) >= total,
        total: total,
      ));
    } catch (e) {
      emit(AdminCampaignsError(e.toString()));
    }
  }

  Future<void> _onCreateCampaign(CreateCampaign event, Emitter<AdminCampaignsState> emit) async {
    try {
      await _adminRepository.createAdminCampaign(event.data);
      emit(const AdminCampaignActionSuccess('Campaign created'));
    } catch (e) {
      emit(AdminCampaignsError(e.toString()));
    }
  }

  Future<void> _onUpdateCampaign(UpdateCampaign event, Emitter<AdminCampaignsState> emit) async {
    try {
      await _adminRepository.updateAdminCampaign(event.id, event.data);
      emit(const AdminCampaignActionSuccess('Campaign updated'));
    } catch (e) {
      emit(AdminCampaignsError(e.toString()));
    }
  }

  Future<void> _onDeleteCampaign(DeleteCampaign event, Emitter<AdminCampaignsState> emit) async {
    try {
      await _adminRepository.deleteAdminCampaign(event.id);
      emit(const AdminCampaignActionSuccess('Campaign deleted'));
    } catch (e) {
      emit(AdminCampaignsError(e.toString()));
    }
  }

  Future<void> _onSendCampaign(SendCampaign event, Emitter<AdminCampaignsState> emit) async {
    try {
      await _adminRepository.sendAdminCampaign(event.id);
      emit(const AdminCampaignActionSuccess('Campaign send initiated'));
    } catch (e) {
      emit(AdminCampaignsError(e.toString()));
    }
  }
}
