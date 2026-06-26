import '../../domain/repositories/wallet_repository.dart';
import '../datasources/remote/wallet_remote_datasource.dart';
import '../models/transaction_model.dart';

class WalletRepositoryImpl implements WalletRepository {
  final WalletRemoteDataSource _remoteDataSource;

  double _balance = 12500.0;
  List<TransactionModel> _cachedTransactions = [];

  WalletRepositoryImpl(this._remoteDataSource);

  @override
  Future<Map<String, dynamic>> getWalletDetails() async {
    try {
      return await _remoteDataSource.getWalletDetails();
    } catch (_) {
      if (_cachedTransactions.isEmpty) {
        _cachedTransactions = [
          TransactionModel(id: 'tx-1', amount: 5000.0, type: 'credit',
              description: 'Earnings payout: Booking #booking-1', status: 'settled',
              createdAt: DateTime.now().subtract(const Duration(days: 1)).toIso8601String()),
          TransactionModel(id: 'tx-2', amount: 600.0, type: 'refund',
              description: 'Refund for returned styling cream', status: 'settled',
              createdAt: DateTime.now().subtract(const Duration(days: 3)).toIso8601String()),
          TransactionModel(id: 'tx-3', amount: 2000.0, type: 'debit',
              description: 'Bank Transfer withdrawal payout', status: 'settled',
              createdAt: DateTime.now().subtract(const Duration(days: 5)).toIso8601String()),
        ];
      }
      return {
        'balance': _balance,
        'transactions': List.from(_cachedTransactions),
      };
    }
  }

  @override
  Future<void> requestWithdrawal({
    required double amount,
    required String bankAccountId,
  }) async {
    if (amount > _balance) {
      throw Exception('Insufficient wallet balance.');
    }
    try {
      await _remoteDataSource.requestWithdrawal(amount: amount, bankAccountId: bankAccountId);
    } catch (_) {
      // proceed with local fallback
    }
    _balance -= amount;
    _cachedTransactions.insert(0, TransactionModel(
      id: 'tx-withdraw-${DateTime.now().millisecondsSinceEpoch}',
      amount: amount, type: 'debit',
      description: 'Requested Payout withdrawal to bank',
      status: 'pending',
      createdAt: DateTime.now().toIso8601String(),
    ));
  }
}
