import '../../../core/network/api_client.dart';
import '../../models/transaction_model.dart';

class WalletRemoteDataSource {
  final ApiClient _apiClient;

  WalletRemoteDataSource(this._apiClient);

  Future<Map<String, dynamic>> getWalletDetails() async {
    final response = await _apiClient.dio.get('/wallet');
    if (response.statusCode == 200 && (response.data['status'] == 'success' || response.data['status'] == 'created')) {
      final wallet = response.data['data'] as Map<String, dynamic>;
      final transactions = await getTransactions();
      return {
        'balance': (wallet['balance'] as num).toDouble(),
        'transactions': transactions,
      };
    }
    throw Exception(response.data['error'] ?? 'Failed to fetch wallet');
  }

  Future<List<TransactionModel>> getTransactions() async {
    final response = await _apiClient.dio.get('/wallet/transactions');
    if (response.statusCode == 200 && (response.data['status'] == 'success' || response.data['status'] == 'created')) {
      final List<dynamic> data = response.data['data'];
      return data.map((e) => TransactionModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception(response.data['error'] ?? 'Failed to fetch transactions');
  }

  Future<void> requestWithdrawal({
    required double amount,
    required String bankAccountId,
  }) async {
    final response = await _apiClient.dio.post(
      '/wallet/withdrawals',
      data: {
        'amount': amount,
        'bank_account_id': bankAccountId,
      },
    );
    if (response.statusCode != 201 || (response.data['status'] != 'success' && response.data['status'] != 'created')) {
      throw Exception(response.data['error'] ?? 'Withdrawal request failed');
    }
  }
}
