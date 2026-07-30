import 'order_item_model.dart';

class OrderModel {
  // Order status constants
  static const String pending = 'pending';
  static const String accepted = 'accepted';
  static const String packed = 'packed';
  static const String readyForPickup = 'ready_for_pickup';
  static const String driverAssigned = 'driver_assigned';
  static const String driverAccepted = 'driver_accepted';
  static const String assigned = 'assigned';
  static const String pickedUp = 'picked_up';
  static const String outForDelivery = 'out_for_delivery';
  static const String delivered = 'delivered';
  static const String cancelled = 'cancelled';
  static const String returnRequested = 'return_requested';
  static const String returnApproved = 'return_approved';
  static const String returnRejected = 'return_rejected';
  static const String returnPickupAssigned = 'return_pickup_assigned';
  static const String returnPickedUp = 'return_picked_up';
  static const String returnReceived = 'return_received';
  static const String refundProcessing = 'refund_processing';
  static const String returned = 'returned';
  static const String refunded = 'refunded';

  final String id;
  final String orderNumber;
  final String status;
  final double itemsTotal;
  final double shippingCharge;
  final double taxAmount;
  final double discountAmount;
  final double finalAmount;
  final String paymentStatus;
  final String? paymentMethod;
  final List<OrderItemModel>? items;

  // Customer info
  final String? customerName;
  final String? customerPhone;
  final Map<String, dynamic>? shippingAddress;

  // Delivery tracking
  final String? deliveryPartnerId;
  final DateTime? assignedAt;
  final DateTime? pickedUpAt;
  final Map<String, dynamic>? deliveryPartner;

  // Timeline / status log
  final List<Map<String, dynamic>>? statusLog;

  // Coordinates
  final double? vendorLatitude;
  final double? vendorLongitude;
  final double? customerLatitude;
  final double? customerLongitude;

  // Meta
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? cancellationReason;

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
    this.paymentMethod,
    this.items,
    this.customerName,
    this.customerPhone,
    this.shippingAddress,
    this.deliveryPartnerId,
    this.assignedAt,
    this.pickedUpAt,
    this.deliveryPartner,
    this.statusLog,
    this.createdAt,
    this.updatedAt,
    this.cancellationReason,
    this.vendorLatitude,
    this.vendorLongitude,
    this.customerLatitude,
    this.customerLongitude,
  });

  static double? _numToDouble(dynamic val) {
    if (val == null) return null;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val);
    return null;
  }

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
      paymentMethod: json['payment_method'] as String?,
      items: json['items'] != null
          ? (json['items'] as List<dynamic>)
              .map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      customerName: json['customer_name'] as String? ?? (json['customer'] as Map<String, dynamic>?)?['full_name'] as String?,
      customerPhone: json['customer_phone'] as String? ?? (json['customer'] as Map<String, dynamic>?)?['phone'] as String?,
      shippingAddress: json['shipping_address'] as Map<String, dynamic>?,
      deliveryPartnerId: json['delivery_partner_id'] as String?,
      assignedAt: json['assigned_at'] != null ? DateTime.tryParse(json['assigned_at'] as String) : null,
      pickedUpAt: json['picked_up_at'] != null ? DateTime.tryParse(json['picked_up_at'] as String) : null,
      deliveryPartner: json['delivery_partner'] as Map<String, dynamic>?,
      statusLog: json['status_log'] != null
          ? (json['status_log'] as List<dynamic>)
              .map((e) => e as Map<String, dynamic>)
              .toList()
          : null,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
      cancellationReason: json['cancellation_reason'] as String?,
      vendorLatitude: _numToDouble(json['vendor_latitude']) ?? _numToDouble((json['vendor'] as Map<String, dynamic>?)?['latitude']),
      vendorLongitude: _numToDouble(json['vendor_longitude']) ?? _numToDouble((json['vendor'] as Map<String, dynamic>?)?['longitude']),
      customerLatitude: _numToDouble(json['customer_latitude']) ?? _numToDouble((json['shipping_address'] as Map<String, dynamic>?)?['latitude']),
      customerLongitude: _numToDouble(json['customer_longitude']) ?? _numToDouble((json['shipping_address'] as Map<String, dynamic>?)?['longitude']),
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
      'items': items?.map((e) => e.toJson()).toList(),
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'shipping_address': shippingAddress,
      'delivery_partner_id': deliveryPartnerId,
      'assigned_at': assignedAt?.toIso8601String(),
      'picked_up_at': pickedUpAt?.toIso8601String(),
      'delivery_partner': deliveryPartner,
      'status_log': statusLog,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'cancellation_reason': cancellationReason,
      'vendor_latitude': vendorLatitude,
      'vendor_longitude': vendorLongitude,
      'customer_latitude': customerLatitude,
      'customer_longitude': customerLongitude,
    };
  }
}
