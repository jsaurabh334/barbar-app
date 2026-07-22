part of 'admin_wallet_bloc.dart';

abstract class AdminWalletState extends Equatable {
  const AdminWalletState();
  @override
  List<Object?> get props => [];
}

class AdminWalletInitial extends AdminWalletState {}

class AdminWalletLoading extends AdminWalletState {}

class AdminWalletLoaded extends AdminWalletState {
  final List<WalletAdminModel> wallets;
  final int currentPage;
  final bool hasReachedMax;
  final int total;

  const AdminWalletLoaded({
    required this.wallets,
    required this.currentPage,
    required this.hasReachedMax,
    required this.total,
  });

  @override
  List<Object?> get props => [wallets, currentPage, hasReachedMax, total];
}

class AdminWalletDetailLoading extends AdminWalletState {}

class AdminWalletDetailLoaded extends AdminWalletState {
  final WalletAdminModel wallet;
  final List<Map<String, dynamic>> transactions;

  const AdminWalletDetailLoaded({required this.wallet, required this.transactions});

  @override
  List<Object?> get props => [wallet, transactions];
}

class AdminWalletActionSuccess extends AdminWalletState {
  final String message;
  const AdminWalletActionSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

class AdminWalletError extends AdminWalletState {
  final String message;
  const AdminWalletError(this.message);
  @override
  List<Object?> get props => [message];
}
