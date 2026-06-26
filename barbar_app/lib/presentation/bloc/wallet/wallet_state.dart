import 'package:equatable/equatable.dart';
import '../../../data/models/transaction_model.dart';

abstract class WalletState extends Equatable {
  const WalletState();

  @override
  List<Object?> get props => [];
}

class WalletInitial extends WalletState {}

class WalletLoading extends WalletState {}

class WalletLoaded extends WalletState {
  final double balance;
  final List<TransactionModel> transactions;

  const WalletLoaded({required this.balance, required this.transactions});

  @override
  List<Object?> get props => [balance, transactions];
}

class WithdrawalSuccess extends WalletState {
  final double newBalance;

  const WithdrawalSuccess(this.newBalance);

  @override
  List<Object?> get props => [newBalance];
}

class WalletFailure extends WalletState {
  final String error;

  const WalletFailure(this.error);

  @override
  List<Object?> get props => [error];
}
