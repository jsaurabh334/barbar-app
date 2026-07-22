import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:barbar_app/domain/repositories/admin_repository.dart';

abstract class AdminFinanceEvent extends Equatable {
  const AdminFinanceEvent();
  @override
  List<Object?> get props => [];
}

class LoadRefunds extends AdminFinanceEvent {
  final int page;
  final String? status;
  const LoadRefunds({this.page = 1, this.status});
  @override
  List<Object?> get props => [page, status];
}

class ProcessRefund extends AdminFinanceEvent {
  final String refundId;
  final String status;
  final double? amount;
  final String? notes;
  const ProcessRefund(this.refundId, this.status, {this.amount, this.notes});
  @override
  List<Object?> get props => [refundId, status, amount, notes];
}

class LoadRevenueAnalytics extends AdminFinanceEvent {
  final String? period;
  const LoadRevenueAnalytics({this.period});
  @override
  List<Object?> get props => [period];
}

class LoadTaxSettings extends AdminFinanceEvent {
  const LoadTaxSettings();
  @override
  List<Object?> get props => [];
}

class CreateTaxSetting extends AdminFinanceEvent {
  final Map<String, dynamic> data;
  const CreateTaxSetting(this.data);
  @override
  List<Object?> get props => [data];
}

class UpdateTaxSetting extends AdminFinanceEvent {
  final String id;
  final Map<String, dynamic> data;
  const UpdateTaxSetting(this.id, this.data);
  @override
  List<Object?> get props => [id, data];
}

class DeleteTaxSetting extends AdminFinanceEvent {
  final String id;
  const DeleteTaxSetting(this.id);
  @override
  List<Object?> get props => [id];
}

class LoadDashboard extends AdminFinanceEvent {
  const LoadDashboard();
  @override
  List<Object?> get props => [];
}

abstract class AdminFinanceState extends Equatable {
  const AdminFinanceState();
  @override
  List<Object?> get props => [];
}

class AdminFinanceInitial extends AdminFinanceState {}

class AdminFinanceLoading extends AdminFinanceState {}

class RefundsLoaded extends AdminFinanceState {
  final List<dynamic> refunds;
  final int currentPage;
  final bool hasReachedMax;
  const RefundsLoaded({required this.refunds, this.currentPage = 1, this.hasReachedMax = false});
  @override
  List<Object?> get props => [refunds, currentPage, hasReachedMax];
}

class RevenueAnalyticsLoaded extends AdminFinanceState {
  final Map<String, dynamic> data;
  const RevenueAnalyticsLoaded(this.data);
  @override
  List<Object?> get props => [data];
}

class TaxSettingsLoaded extends AdminFinanceState {
  final List<dynamic> taxSettings;
  const TaxSettingsLoaded(this.taxSettings);
  @override
  List<Object?> get props => [taxSettings];
}

class DashboardLoaded extends AdminFinanceState {
  final Map<String, dynamic> data;
  const DashboardLoaded(this.data);
  @override
  List<Object?> get props => [data];
}

class AdminFinanceError extends AdminFinanceState {
  final String message;
  const AdminFinanceError(this.message);
  @override
  List<Object?> get props => [message];
}

class AdminFinanceActionSuccess extends AdminFinanceState {
  final String message;
  const AdminFinanceActionSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

class AdminFinanceBloc extends Bloc<AdminFinanceEvent, AdminFinanceState> {
  final AdminRepository adminRepository;

  AdminFinanceBloc({required this.adminRepository}) : super(AdminFinanceInitial()) {
    on<LoadRefunds>(_onLoadRefunds);
    on<ProcessRefund>(_onProcessRefund);
    on<LoadRevenueAnalytics>(_onLoadRevenueAnalytics);
    on<LoadTaxSettings>(_onLoadTaxSettings);
    on<CreateTaxSetting>(_onCreateTaxSetting);
    on<UpdateTaxSetting>(_onUpdateTaxSetting);
    on<DeleteTaxSetting>(_onDeleteTaxSetting);
    on<LoadDashboard>(_onLoadDashboard);
  }

  Future<void> _onLoadRefunds(LoadRefunds event, Emitter<AdminFinanceState> emit) async {
    if (event.page == 1) emit(AdminFinanceLoading());
    try {
      final result = await adminRepository.getAdminRefunds(page: event.page, status: event.status);
      final List<dynamic> rawData = (result['data'] is List) ? result['data'] : (result['data']?['data'] ?? []);
      if (state is RefundsLoaded && event.page > 1) {
        final cur = state as RefundsLoaded;
        emit(RefundsLoaded(refunds: cur.refunds + rawData, currentPage: event.page, hasReachedMax: rawData.isEmpty));
      } else {
        emit(RefundsLoaded(refunds: rawData, currentPage: event.page, hasReachedMax: rawData.isEmpty));
      }
    } catch (e) {
      emit(AdminFinanceError(e.toString()));
    }
  }

  Future<void> _onProcessRefund(ProcessRefund event, Emitter<AdminFinanceState> emit) async {
    try {
      await adminRepository.processAdminRefund(event.refundId, event.status, amount: event.amount, notes: event.notes);
      emit(AdminFinanceActionSuccess('Refund ${event.status}'));
    } catch (e) {
      emit(AdminFinanceError(e.toString()));
    }
  }

  Future<void> _onLoadRevenueAnalytics(LoadRevenueAnalytics event, Emitter<AdminFinanceState> emit) async {
    emit(AdminFinanceLoading());
    try {
      final data = await adminRepository.getAdminRevenueAnalytics(period: event.period);
      emit(RevenueAnalyticsLoaded(data));
    } catch (e) {
      emit(AdminFinanceError(e.toString()));
    }
  }

  Future<void> _onLoadTaxSettings(LoadTaxSettings event, Emitter<AdminFinanceState> emit) async {
    emit(AdminFinanceLoading());
    try {
      final data = await adminRepository.getAdminTaxSettings();
      emit(TaxSettingsLoaded(data));
    } catch (e) {
      emit(AdminFinanceError(e.toString()));
    }
  }

  Future<void> _onCreateTaxSetting(CreateTaxSetting event, Emitter<AdminFinanceState> emit) async {
    try {
      await adminRepository.createAdminTaxSetting(event.data);
      emit(AdminFinanceActionSuccess('Tax setting created'));
    } catch (e) {
      emit(AdminFinanceError(e.toString()));
    }
  }

  Future<void> _onUpdateTaxSetting(UpdateTaxSetting event, Emitter<AdminFinanceState> emit) async {
    try {
      await adminRepository.updateAdminTaxSetting(event.id, event.data);
      emit(AdminFinanceActionSuccess('Tax setting updated'));
    } catch (e) {
      emit(AdminFinanceError(e.toString()));
    }
  }

  Future<void> _onDeleteTaxSetting(DeleteTaxSetting event, Emitter<AdminFinanceState> emit) async {
    try {
      await adminRepository.deleteAdminTaxSetting(event.id);
      emit(AdminFinanceActionSuccess('Tax setting deleted'));
    } catch (e) {
      emit(AdminFinanceError(e.toString()));
    }
  }

  Future<void> _onLoadDashboard(LoadDashboard event, Emitter<AdminFinanceState> emit) async {
    emit(AdminFinanceLoading());
    try {
      final data = await adminRepository.getAdminDashboard();
      emit(DashboardLoaded(data));
    } catch (e) {
      emit(AdminFinanceError(e.toString()));
    }
  }
}
