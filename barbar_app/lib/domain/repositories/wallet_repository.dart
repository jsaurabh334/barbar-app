abstract class WalletRepository {
  Future<Map<String, dynamic>> getWalletDetails();
  Future<void> requestWithdrawal({
    required double amount,
    required String bankAccountId,
  });
}
