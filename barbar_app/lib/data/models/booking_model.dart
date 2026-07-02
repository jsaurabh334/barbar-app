import 'service_model.dart';

class BookingModel {
  final String id;
  final String barberId;
  final String customerId;
  final String status;
  final String scheduledStart;
  final String scheduledEnd;
  final int queuePosition;
  final int estimatedWaitMinutes;
  final double finalPrice;
  final String paymentStatus;
  final String customerName;
  final List<ServiceModel> services;

  BookingModel({
    required this.id,
    required this.barberId,
    required this.customerId,
    required this.status,
    required this.scheduledStart,
    required this.scheduledEnd,
    required this.queuePosition,
    required this.estimatedWaitMinutes,
    required this.finalPrice,
    required this.paymentStatus,
    this.customerName = 'Guest Customer',
    this.services = const [],
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    var rawServices = json['services'] as List?;
    List<ServiceModel> serviceList = rawServices != null
        ? rawServices.map((e) => ServiceModel.fromJson(e as Map<String, dynamic>)).toList()
        : [];

    String parsedCustomerName = 'Guest Customer';
    if (json['customer'] != null && json['customer']['full_name'] != null) {
      parsedCustomerName = json['customer']['full_name'] as String;
    }

    return BookingModel(
      id: json['id'] as String,
      barberId: json['barber_id'] as String,
      customerId: json['customer_id'] as String,
      status: json['status'] as String,
      scheduledStart: json['scheduled_start'] as String,
      scheduledEnd: json['scheduled_end'] as String,
      queuePosition: (json['queue_position'] as num?)?.toInt() ?? 0,
      estimatedWaitMinutes: (json['estimated_wait_minutes'] as num?)?.toInt() ?? 0,
      finalPrice: (json['final_price'] as num?)?.toDouble() ?? 0.0,
      paymentStatus: (json['payment_status'] as String?) ?? 'pending',
      customerName: parsedCustomerName,
      services: serviceList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'barber_id': barberId,
      'customer_id': customerId,
      'status': status,
      'scheduled_start': scheduledStart,
      'scheduled_end': scheduledEnd,
      'queue_position': queuePosition,
      'estimated_wait_minutes': estimatedWaitMinutes,
      'final_price': finalPrice,
      'payment_status': paymentStatus,
      'customer_name': customerName,
      'services': services.map((e) => e.toJson()).toList(),
    };
  }

  BookingModel copyWith({
    String? id,
    String? barberId,
    String? customerId,
    String? status,
    String? scheduledStart,
    String? scheduledEnd,
    int? queuePosition,
    int? estimatedWaitMinutes,
    double? finalPrice,
    String? paymentStatus,
    String? customerName,
    List<ServiceModel>? services,
  }) {
    return BookingModel(
      id: id ?? this.id,
      barberId: barberId ?? this.barberId,
      customerId: customerId ?? this.customerId,
      status: status ?? this.status,
      scheduledStart: scheduledStart ?? this.scheduledStart,
      scheduledEnd: scheduledEnd ?? this.scheduledEnd,
      queuePosition: queuePosition ?? this.queuePosition,
      estimatedWaitMinutes: estimatedWaitMinutes ?? this.estimatedWaitMinutes,
      finalPrice: finalPrice ?? this.finalPrice,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      customerName: customerName ?? this.customerName,
      services: services ?? this.services,
    );
  }
}
