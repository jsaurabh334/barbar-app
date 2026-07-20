class OrderItemModel {
  final String productId;
  final String productName;
  final int quantity;
  final double price;
  final String? variantName;

  OrderItemModel({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
    this.variantName,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      productId: json['product_id'] as String? ?? '',
      productName: json['product_name'] as String? ?? 'Unknown Product',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      variantName: json['variant_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'product_name': productName,
      'quantity': quantity,
      'price': price,
      'variant_name': variantName,
    };
  }
}
