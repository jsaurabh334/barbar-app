import 'package:equatable/equatable.dart';
import '../../../data/models/order_model.dart';
import '../../../data/models/product_model.dart';

abstract class MarketplaceState extends Equatable {
  const MarketplaceState();

  @override
  List<Object?> get props => [];
}

class MarketplaceInitial extends MarketplaceState {}

class MarketplaceLoading extends MarketplaceState {}

class ProductsLoaded extends MarketplaceState {
  final List<ProductModel> products;
  final Map<String, int> cart;

  const ProductsLoaded({required this.products, required this.cart});

  @override
  List<Object?> get props => [products, cart];
}

class OrderCreatedSuccess extends MarketplaceState {
  final OrderModel order;

  const OrderCreatedSuccess(this.order);

  @override
  List<Object?> get props => [order];
}

class OrdersLoaded extends MarketplaceState {
  final List<OrderModel> orders;

  const OrdersLoaded(this.orders);

  @override
  List<Object?> get props => [orders];
}

class MarketplaceFailure extends MarketplaceState {
  final String error;

  const MarketplaceFailure(this.error);

  @override
  List<Object?> get props => [error];
}
