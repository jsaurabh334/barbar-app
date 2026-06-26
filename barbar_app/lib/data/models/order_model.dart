class OrderModel {
  final String id;
  final String orderNumber;
  final String status;
  final double itemsTotal;
  final double shippingCharge;
  final double taxAmount;
  final double discountAmount;
  final double finalAmount;
  final String paymentStatus;

  OrderModel({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.itemsTotal,
    required this.shippingCharge,
    required this.taxAmount,
    required this.discountAmount,
    required this.finalAmount,
    required this.paymentStatus,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] as String,
      orderNumber: json['order_number'] as String,
      status: json['status'] as String,
      itemsTotal: (json['items_total'] as num).toDouble(),
      shippingCharge: (json['shipping_charge'] as num).toDouble(),
      taxAmount: (json['tax_amount'] as num).toDouble(),
      discountAmount: (json['discount_amount'] as num).toDouble(),
      finalAmount: (json['final_amount'] as num).toDouble(),
      paymentStatus: json['payment_status'] as String? ?? 'pending',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_number': orderNumber,
      'status': status,
      'items_total': itemsTotal,
      'shipping_charge': shippingCharge,
      'tax_amount': taxAmount,
      'discount_amount': discountAmount,
      'final_amount': finalAmount,
      'payment_status': paymentStatus,
    };
  }
}
