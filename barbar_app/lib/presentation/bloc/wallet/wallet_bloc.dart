import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/transaction_model.dart';
import '../../../domain/repositories/wallet_repository.dart';
import 'wallet_event.dart';
import 'wallet_state.dart';

class WalletBloc extends Bloc<WalletEvent, WalletState> {
  final WalletRepository _walletRepository;

  WalletBloc(this._walletRepository) : super(WalletInitial()) {
    on<FetchWalletDetails>(_onFetchWalletDetails);
    on<RequestWithdrawal>(_onRequestWithdrawal);
  }

  Future<void> _onFetchWalletDetails(FetchWalletDetails event, Emitter<WalletState> emit) async {
    emit(WalletLoading());
    try {
      final details = await _walletRepository.getWalletDetails();
      emit(WalletLoaded(
        balance: details['balance'] as double,
        transactions: (details['transactions'] as List).cast<TransactionModel>(),
      ));
    } catch (e) {
      emit(WalletFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onRequestWithdrawal(RequestWithdrawal event, Emitter<WalletState> emit) async {
    emit(WalletLoading());
    try {
      await _walletRepository.requestWithdrawal(
        amount: event.amount,
        bankAccountId: event.bankAccountId,
      );
      final details = await _walletRepository.getWalletDetails();
      emit(WalletLoaded(
        balance: details['balance'] as double,
        transactions: (details['transactions'] as List).cast<TransactionModel>(),
      ));
    } catch (e) {
      emit(WalletFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
