import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:barbar_app/domain/repositories/admin_repository.dart';
import 'package:barbar_app/data/models/dashboard_stats_model.dart';

// --- Events ---
abstract class AdminDashboardEvent extends Equatable {
  const AdminDashboardEvent();
  @override
  List<Object> get props => [];
}

class LoadDashboardData extends AdminDashboardEvent {}

// --- States ---
abstract class AdminDashboardState extends Equatable {
  const AdminDashboardState();
  @override
  List<Object> get props => [];
}

class AdminDashboardInitial extends AdminDashboardState {}

class AdminDashboardLoading extends AdminDashboardState {}

class AdminDashboardLoaded extends AdminDashboardState {
  final DashboardStatsModel stats;
  const AdminDashboardLoaded(this.stats);
  @override
  List<Object> get props => [stats];
}

class AdminDashboardError extends AdminDashboardState {
  final String message;
  const AdminDashboardError(this.message);
  @override
  List<Object> get props => [message];
}

// --- Bloc ---
class AdminDashboardBloc extends Bloc<AdminDashboardEvent, AdminDashboardState> {
  final AdminRepository adminRepository;

  AdminDashboardBloc({required this.adminRepository}) : super(AdminDashboardInitial()) {
    on<LoadDashboardData>(_onLoadDashboardData);
  }

  Future<void> _onLoadDashboardData(LoadDashboardData event, Emitter<AdminDashboardState> emit) async {
    emit(AdminDashboardLoading());
    try {
      final stats = await adminRepository.getDashboardStats();
      emit(AdminDashboardLoaded(stats));
    } catch (e) {
      emit(AdminDashboardError(e.toString()));
    }
  }
}
