part of 'admin_settlements_bloc.dart';

abstract class AdminSettlementsState extends Equatable {
  const AdminSettlementsState();
  @override
  List<Object?> get props => [];
}

class AdminSettlementsInitial extends AdminSettlementsState {}

class AdminSettlementsLoading extends AdminSettlementsState {}

class AdminSettlementsLoaded extends AdminSettlementsState {
  final List<SettlementModel> settlements;
  final int currentPage;
  final bool hasReachedMax;
  final int total;

  const AdminSettlementsLoaded({
    required this.settlements,
    required this.currentPage,
    required this.hasReachedMax,
    required this.total,
  });

  @override
  List<Object?> get props => [settlements, currentPage, hasReachedMax, total];
}

class AdminSettlementDetailLoading extends AdminSettlementsState {}

class AdminSettlementDetailLoaded extends AdminSettlementsState {
  final SettlementModel settlement;
  const AdminSettlementDetailLoaded(this.settlement);
  @override
  List<Object?> get props => [settlement];
}

class AdminSettlementActionSuccess extends AdminSettlementsState {
  final String message;
  const AdminSettlementActionSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

class AdminSettlementsError extends AdminSettlementsState {
  final String message;
  const AdminSettlementsError(this.message);
  @override
  List<Object?> get props => [message];
}
