import 'package:equatable/equatable.dart';

abstract class WalletEvent extends Equatable {
  const WalletEvent();

  @override
  List<Object?> get props => [];
}

class FetchWalletDetails extends WalletEvent {}

class RequestWithdrawal extends WalletEvent {
  final double amount;
  final String bankAccountId;

  const RequestWithdrawal({required this.amount, required this.bankAccountId});

  @override
  List<Object?> get props => [amount, bankAccountId];
}
