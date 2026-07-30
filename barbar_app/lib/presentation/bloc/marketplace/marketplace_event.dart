import 'package:equatable/equatable.dart';
import '../../../data/models/product_model.dart';

abstract class MarketplaceEvent extends Equatable {
  const MarketplaceEvent();

  @override
  List<Object?> get props => [];
}

class FetchProducts extends MarketplaceEvent {}

class AddToCart extends MarketplaceEvent {
  final ProductModel product;
  final int quantity;

  const AddToCart(this.product, {this.quantity = 1});

  @override
  List<Object?> get props => [product, quantity];
}

class RemoveFromCart extends MarketplaceEvent {
  final String productId;

  const RemoveFromCart(this.productId);

  @override
  List<Object?> get props => [productId];
}

class ClearCart extends MarketplaceEvent {}

class PlaceOrder extends MarketplaceEvent {
  final String vendorId;
  final String shippingAddressId;
  final String? couponCode;
  final String paymentMethod;

  const PlaceOrder({
    required this.vendorId,
    required this.shippingAddressId,
    this.couponCode,
    this.paymentMethod = 'cod',
  });

  @override
  List<Object?> get props => [vendorId, shippingAddressId, couponCode, paymentMethod];
}

class FetchAllOrders extends MarketplaceEvent {}

class UpdateOrderStatus extends MarketplaceEvent {
  final String orderId;
  final String status;

  const UpdateOrderStatus({required this.orderId, required this.status});

  @override
  List<Object?> get props => [orderId, status];
}

class CancelOrder extends MarketplaceEvent {
  final String orderId;
  final String? reason;

  const CancelOrder({required this.orderId, this.reason});

  @override
  List<Object?> get props => [orderId, reason];
}

class SubmitReturnRequest extends MarketplaceEvent {
  final String orderId;
  final String reason;
  final List<String>? images;

  const SubmitReturnRequest({
    required this.orderId,
    required this.reason,
    this.images,
  });

  @override
  List<Object?> get props => [orderId, reason, images];
}

class ReportIssue extends MarketplaceEvent {
  final String orderId;
  final String issueType;
  final String description;

  const ReportIssue({
    required this.orderId,
    required this.issueType,
    required this.description,
  });

  @override
  List<Object?> get props => [orderId, issueType, description];
}

class InitiateOrderPayment extends MarketplaceEvent {
  final String orderId;
  final String gateway;

  const InitiateOrderPayment({required this.orderId, required this.gateway});

  @override
  List<Object?> get props => [orderId, gateway];
}

class VerifyOrderPayment extends MarketplaceEvent {
  final String paymentId;
  final String gateway;
  final String razorpayOrderId;
  final String razorpayPaymentId;
  final String razorpaySignature;

  const VerifyOrderPayment({
    required this.paymentId,
    required this.gateway,
    required this.razorpayOrderId,
    required this.razorpayPaymentId,
    required this.razorpaySignature,
  });

  @override
  List<Object?> get props => [paymentId, gateway, razorpayOrderId, razorpayPaymentId, razorpaySignature];
}
