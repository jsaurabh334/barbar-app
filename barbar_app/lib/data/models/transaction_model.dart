class TransactionModel {
  final String id;
  final double amount;
  final String type; // credit, debit, refund
  final String description;
  final String status;
  final String createdAt;

  TransactionModel({
    required this.id,
    required this.amount,
    required this.type,
    required this.description,
    required this.status,
    required this.createdAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: json['txn_type'] as String? ?? json['type'] as String? ?? 'credit',
      description: json['description'] as String? ?? '',
      status: json['status'] as String? ?? 'completed',
      createdAt: json['created_at'] as String? ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'type': type,
      'description': description,
      'status': status,
      'created_at': createdAt,
    };
  }
}
