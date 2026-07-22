class SettlementModel {
  final String id;
  final String vendorId;
  final String businessName;
  final double amount;
  final double feeAmount;
  final double netAmount;
  final String status;
  final String? bankAccount;
  final String? utrNumber;
  final DateTime createdAt;
  final DateTime? processedAt;

  SettlementModel({
    required this.id,
    required this.vendorId,
    required this.businessName,
    required this.amount,
    required this.feeAmount,
    required this.netAmount,
    required this.status,
    this.bankAccount,
    this.utrNumber,
    required this.createdAt,
    this.processedAt,
  });

  factory SettlementModel.fromJson(Map<String, dynamic> json) {
    return SettlementModel(
      id: json['id'] as String,
      vendorId: json['vendor_id'] as String,
      businessName: (json['business_name'] as String?) ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      feeAmount: (json['fee_amount'] as num?)?.toDouble() ?? 0.0,
      netAmount: (json['net_amount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'pending',
      bankAccount: json['bank_account'] as String?,
      utrNumber: json['utr_number'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      processedAt: json['processed_at'] != null ? DateTime.tryParse(json['processed_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'vendor_id': vendorId,
    'business_name': businessName,
    'amount': amount,
    'fee_amount': feeAmount,
    'net_amount': netAmount,
    'status': status,
    'bank_account': bankAccount,
    'utr_number': utrNumber,
    'created_at': createdAt.toIso8601String(),
    'processed_at': processedAt?.toIso8601String(),
  };
}

class WalletAdminModel {
  final String id;
  final String? userId;
  final String? vendorId;
  final String ownerName;
  final String ownerType;
  final double balance;
  final double lockedBalance;
  final bool isActive;

  WalletAdminModel({
    required this.id,
    this.userId,
    this.vendorId,
    required this.ownerName,
    required this.ownerType,
    required this.balance,
    required this.lockedBalance,
    required this.isActive,
  });

  factory WalletAdminModel.fromJson(Map<String, dynamic> json) {
    return WalletAdminModel(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      vendorId: json['vendor_id'] as String?,
      ownerName: (json['owner_name'] as String?) ?? '',
      ownerType: (json['owner_type'] as String?) ?? '',
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      lockedBalance: (json['locked_balance'] as num?)?.toDouble() ?? 0.0,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}

class CommissionTransactionModel {
  final String id;
  final String orderId;
  final String vendorId;
  final double orderAmount;
  final double commissionRate;
  final double commissionAmount;
  final double platformFee;
  final double taxAmount;
  final double netAmount;
  final String status;
  final DateTime? settledAt;
  final DateTime createdAt;

  CommissionTransactionModel({
    required this.id,
    required this.orderId,
    required this.vendorId,
    required this.orderAmount,
    required this.commissionRate,
    required this.commissionAmount,
    required this.platformFee,
    required this.taxAmount,
    required this.netAmount,
    required this.status,
    this.settledAt,
    required this.createdAt,
  });

  factory CommissionTransactionModel.fromJson(Map<String, dynamic> json) {
    return CommissionTransactionModel(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      vendorId: json['vendor_id'] as String,
      orderAmount: (json['order_amount'] as num?)?.toDouble() ?? 0.0,
      commissionRate: (json['commission_rate'] as num?)?.toDouble() ?? 0.0,
      commissionAmount: (json['commission_amount'] as num?)?.toDouble() ?? 0.0,
      platformFee: (json['platform_fee'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (json['tax_amount'] as num?)?.toDouble() ?? 0.0,
      netAmount: (json['net_amount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'pending',
      settledAt: json['settled_at'] != null ? DateTime.tryParse(json['settled_at'] as String) : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
