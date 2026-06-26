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

  const AddToCart(this.product);

  @override
  List<Object?> get props => [product];
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

  const PlaceOrder({
    required this.vendorId,
    required this.shippingAddressId,
    this.couponCode,
  });

  @override
  List<Object?> get props => [vendorId, shippingAddressId, couponCode];
}

class FetchAllOrders extends MarketplaceEvent {}

class UpdateOrderStatus extends MarketplaceEvent {
  final String orderId;
  final String status;

  const UpdateOrderStatus({required this.orderId, required this.status});

  @override
  List<Object?> get props => [orderId, status];
}
