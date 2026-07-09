import '../../domain/repositories/wallet_repository.dart';
import '../datasources/remote/wallet_remote_datasource.dart';

class WalletRepositoryImpl implements WalletRepository {
  final WalletRemoteDataSource _remoteDataSource;

  WalletRepositoryImpl(this._remoteDataSource);

  @override
  Future<Map<String, dynamic>> getWalletDetails() async {
    return await _remoteDataSource.getWalletDetails();
  }

  @override
  Future<void> requestWithdrawal({
    required double amount,
    required String bankAccountId,
  }) async {
    await _remoteDataSource.requestWithdrawal(amount: amount, bankAccountId: bankAccountId);
  }
}
