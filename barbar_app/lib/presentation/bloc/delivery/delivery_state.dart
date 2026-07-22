import 'package:equatable/equatable.dart';
import '../../../data/models/delivery_partner_model.dart';
import '../../../data/models/order_model.dart';

abstract class DeliveryState extends Equatable {
  const DeliveryState();

  @override
  List<Object?> get props => [];
}

class DeliveryInitial extends DeliveryState {}

class DeliveryLoading extends DeliveryState {}

class DeliveryFailure extends DeliveryState {
  final String error;

  const DeliveryFailure(this.error);

  @override
  List<Object?> get props => [error];
}

class DeliveryProfileLoaded extends DeliveryState {
  final DeliveryPartnerModel profile;

  const DeliveryProfileLoaded(this.profile);

  @override
  List<Object?> get props => [profile];
}

class DeliveryNoProfile extends DeliveryState {}

class DeliveryPresenceUpdated extends DeliveryState {
  final String status;

  const DeliveryPresenceUpdated(this.status);

  @override
  List<Object?> get props => [status];
}

class DeliveryOrdersLoaded extends DeliveryState {
  final List<OrderModel> orders;

  const DeliveryOrdersLoaded(this.orders);

  @override
  List<Object?> get props => [orders];
}

class DeliveryBankAccountLoaded extends DeliveryState {
  final Map<String, dynamic> account;

  const DeliveryBankAccountLoaded(this.account);

  @override
  List<Object?> get props => [account];
}

class DeliveryEarningsLoaded extends DeliveryState {
  final List<Map<String, dynamic>> earnings;
  final Map<String, dynamic>? summary;

  const DeliveryEarningsLoaded(this.earnings, {this.summary});

  @override
  List<Object?> get props => [earnings, summary];
}

class DeliveryOrderDetailLoaded extends DeliveryState {
  final OrderModel order;

  const DeliveryOrderDetailLoaded(this.order);

  @override
  List<Object?> get props => [order];
}

class DeliverySuccess extends DeliveryState {
  final String message;

  const DeliverySuccess(this.message);

  @override
  List<Object?> get props => [message];
}
