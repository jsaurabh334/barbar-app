import 'package:equatable/equatable.dart';

class VendorPurchaseModel extends Equatable {
  final String id;
  final String vendorId;
  final String productId;
  final String? productName;
  final String? variantId;
  final String? variantName;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final String? supplierName;
  final String? invoiceNumber;
  final String? notes;
  final DateTime? purchasedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const VendorPurchaseModel({
    required this.id,
    required this.vendorId,
    required this.productId,
    this.productName,
    this.variantId,
    this.variantName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.supplierName,
    this.invoiceNumber,
    this.notes,
    this.purchasedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory VendorPurchaseModel.fromJson(Map<String, dynamic> json) {
    String? pName;
    if (json['product'] is Map) {
      pName = json['product']['name'] as String?;
    }
    String? vName;
    if (json['variant'] is Map) {
      vName = json['variant']['name'] as String?;
    }
    return VendorPurchaseModel(
      id: json['id'] ?? '',
      vendorId: json['vendor_id'] ?? '',
      productId: json['product_id'] ?? '',
      productName: pName,
      variantId: json['variant_id'],
      variantName: vName,
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0,
      totalPrice: (json['total_price'] as num?)?.toDouble() ?? 0,
      supplierName: json['supplier_name'],
      invoiceNumber: json['invoice_number'],
      notes: json['notes'],
      purchasedAt: json['purchased_at'] != null ? DateTime.tryParse(json['purchased_at']) : null,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'variant_id': variantId,
      'quantity': quantity,
      'unit_price': unitPrice,
      'supplier_name': supplierName,
      'invoice_number': invoiceNumber,
      'notes': notes,
      if (purchasedAt != null) 'purchased_at': purchasedAt!.toIso8601String(),
    };
  }

  VendorPurchaseModel copyWith({
    String? id,
    String? vendorId,
    String? productId,
    String? productName,
    String? variantId,
    String? variantName,
    int? quantity,
    double? unitPrice,
    double? totalPrice,
    String? supplierName,
    String? invoiceNumber,
    String? notes,
    DateTime? purchasedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VendorPurchaseModel(
      id: id ?? this.id,
      vendorId: vendorId ?? this.vendorId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      variantId: variantId ?? this.variantId,
      variantName: variantName ?? this.variantName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      supplierName: supplierName ?? this.supplierName,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      notes: notes ?? this.notes,
      purchasedAt: purchasedAt ?? this.purchasedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id, vendorId, productId, productName, variantId, variantName,
    quantity, unitPrice, totalPrice, supplierName, invoiceNumber,
    notes, purchasedAt, createdAt, updatedAt,
  ];

  @override
  String toString() {
    return 'VendorPurchaseModel(id: $id, productId: $productId, quantity: $quantity, totalPrice: $totalPrice)';
  }
}
