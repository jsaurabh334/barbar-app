import 'dart:convert';
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
  final String paymentMethod;
  final String customerName;
  final String shopName;
  final List<ServiceModel> services;
  final bool isHomeService;
  final Map<String, dynamic>? homeServiceAddress;
  final double travelDistanceKm;
  final double travelCharge;
  final Map<String, dynamic>? customer;
  final int travelTimeMin;
  final String? customerNotes;
  final String? staffId;
  final Map<String, dynamic>? staff;
  final String? queueAssignedAt;
  final bool isLate;
  final String? lateAt;
  final String? graceExtendedUntil;
  final String? imComingAt;
  final bool canCallShop;
  final bool canCallCustomer;
  final String? maskedShopPhone;
  final String? maskedCustomerPhone;

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
    this.paymentMethod = '',
    this.customerName = 'Guest Customer',
    this.shopName = '',
    this.services = const [],
    this.isHomeService = false,
    this.homeServiceAddress,
    this.travelDistanceKm = 0,
    this.travelCharge = 0,
    this.customer,
    this.travelTimeMin = 0,
    this.customerNotes,
    this.staffId,
    this.staff,
    this.queueAssignedAt,
    this.isLate = false,
    this.lateAt,
    this.graceExtendedUntil,
    this.imComingAt,
    this.canCallShop = false,
    this.canCallCustomer = false,
    this.maskedShopPhone,
    this.maskedCustomerPhone,
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

    String parsedShopName = '';
    if (json['barber'] != null && json['barber']['shop_name'] != null) {
      parsedShopName = json['barber']['shop_name'] as String;
    }

    return BookingModel(
      id: (json['id'] as String?) ?? '',
      barberId: (json['barber_id'] as String?) ?? '',
      customerId: (json['customer_id'] as String?) ?? '',
      status: (json['status'] as String?) ?? 'pending',
      scheduledStart: (json['scheduled_start'] as String?) ?? '',
      scheduledEnd: (json['scheduled_end'] as String?) ?? '',
      queuePosition: (json['queue_position'] as num?)?.toInt() ?? 0,
      estimatedWaitMinutes: (json['estimated_wait_minutes'] as num?)?.toInt() ?? 0,
      finalPrice: (json['final_price'] as num?)?.toDouble() ?? 0.0,
      paymentStatus: (json['payment_status'] as String?) ?? 'pending',
      paymentMethod: (json['payment_method'] as String?) ?? '',
      customerName: parsedCustomerName,
      shopName: parsedShopName,
      services: serviceList,
      isHomeService: json['is_home_service'] as bool? ?? false,
      homeServiceAddress: () {
        final val = json['home_service_address'];
        if (val is Map<String, dynamic>) return val;
        if (val is String && val.isNotEmpty) {
          try {
            return jsonDecode(val) as Map<String, dynamic>;
          } catch (_) {}
        }
        return null;
      }(),
      travelDistanceKm: (json['travel_distance_km'] as num?)?.toDouble() ?? 0,
      travelCharge: (json['travel_charge'] as num?)?.toDouble() ?? 0,
      customer: json['customer'] as Map<String, dynamic>?,
      travelTimeMin: (json['travel_time_minutes'] as num?)?.toInt() ?? 0,
      customerNotes: json['customer_notes'] as String?,
      staffId: json['staff_id'] as String?,
      staff: json['staff'] as Map<String, dynamic>?,
      queueAssignedAt: json['queue_assigned_at'] as String?,
      isLate: json['is_late'] as bool? ?? false,
      lateAt: json['late_at'] as String?,
      graceExtendedUntil: json['grace_extended_until'] as String?,
      imComingAt: json['im_coming_at'] as String?,
      canCallShop: json['can_call_shop'] as bool? ?? false,
      canCallCustomer: json['can_call_customer'] as bool? ?? false,
      maskedShopPhone: json['shop_phone'] as String?,
      maskedCustomerPhone: json['customer_phone'] as String?,
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
      'payment_method': paymentMethod,
      'customer_name': customerName,
      'shop_name': shopName,
      'services': services.map((e) => e.toJson()).toList(),
      'is_home_service': isHomeService,
      'home_service_address': homeServiceAddress,
      'travel_distance_km': travelDistanceKm,
      'travel_charge': travelCharge,
      'customer': customer,
      'travel_time_min': travelTimeMin,
      'customer_notes': customerNotes,
      'queue_assigned_at': queueAssignedAt,
      'is_late': isLate,
      'late_at': lateAt,
      'grace_extended_until': graceExtendedUntil,
      'im_coming_at': imComingAt,
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
    String? paymentMethod,
    String? customerName,
    String? shopName,
    List<ServiceModel>? services,
    bool? isHomeService,
    Map<String, dynamic>? homeServiceAddress,
    double? travelDistanceKm,
    double? travelCharge,
    Map<String, dynamic>? customer,
    int? travelTimeMin,
    String? customerNotes,
    String? staffId,
    Map<String, dynamic>? staff,
    String? queueAssignedAt,
    bool? isLate,
    String? lateAt,
    String? graceExtendedUntil,
    String? imComingAt,
    bool? canCallShop,
    bool? canCallCustomer,
    String? maskedShopPhone,
    String? maskedCustomerPhone,
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
      paymentMethod: paymentMethod ?? this.paymentMethod,
      customerName: customerName ?? this.customerName,
      shopName: shopName ?? this.shopName,
      services: services ?? this.services,
      isHomeService: isHomeService ?? this.isHomeService,
      homeServiceAddress: homeServiceAddress ?? this.homeServiceAddress,
      travelDistanceKm: travelDistanceKm ?? this.travelDistanceKm,
      travelCharge: travelCharge ?? this.travelCharge,
      customer: customer ?? this.customer,
      travelTimeMin: travelTimeMin ?? this.travelTimeMin,
      customerNotes: customerNotes ?? this.customerNotes,
      staffId: staffId ?? this.staffId,
      staff: staff ?? this.staff,
      queueAssignedAt: queueAssignedAt ?? this.queueAssignedAt,
      isLate: isLate ?? this.isLate,
      lateAt: lateAt ?? this.lateAt,
      graceExtendedUntil: graceExtendedUntil ?? this.graceExtendedUntil,
      imComingAt: imComingAt ?? this.imComingAt,
      canCallShop: canCallShop ?? this.canCallShop,
      canCallCustomer: canCallCustomer ?? this.canCallCustomer,
      maskedShopPhone: maskedShopPhone ?? this.maskedShopPhone,
      maskedCustomerPhone: maskedCustomerPhone ?? this.maskedCustomerPhone,
    );
  }
}
