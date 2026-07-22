part of 'admin_wallet_bloc.dart';

abstract class AdminWalletEvent extends Equatable {
  const AdminWalletEvent();
  @override
  List<Object?> get props => [];
}

class LoadAdminWallets extends AdminWalletEvent {
  final int page;
  final String? type;
  final bool? isActive;
  const LoadAdminWallets({this.page = 1, this.type, this.isActive});
  @override
  List<Object?> get props => [page, type, isActive];
}

class LoadAdminWalletDetail extends AdminWalletEvent {
  final String id;
  const LoadAdminWalletDetail(this.id);
  @override
  List<Object?> get props => [id];
}

class CreditAdminWallet extends AdminWalletEvent {
  final String id;
  final double amount;
  final String? description;
  const CreditAdminWallet({required this.id, required this.amount, this.description});
  @override
  List<Object?> get props => [id, amount, description];
}

class DebitAdminWallet extends AdminWalletEvent {
  final String id;
  final double amount;
  final String? description;
  const DebitAdminWallet({required this.id, required this.amount, this.description});
  @override
  List<Object?> get props => [id, amount, description];
}

class ToggleAdminWalletFreeze extends AdminWalletEvent {
  final String id;
  const ToggleAdminWalletFreeze(this.id);
  @override
  List<Object?> get props => [id];
}
