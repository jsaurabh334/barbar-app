import 'package:equatable/equatable.dart';

abstract class DeliveryEvent extends Equatable {
  const DeliveryEvent();

  @override
  List<Object?> get props => [];
}

class LoadDeliveryProfile extends DeliveryEvent {}

class RegisterDelivery extends DeliveryEvent {
  final Map<String, dynamic> data;

  const RegisterDelivery(this.data);

  @override
  List<Object?> get props => [data];
}

class SaveBankAccount extends DeliveryEvent {
  final Map<String, dynamic> data;

  const SaveBankAccount(this.data);

  @override
  List<Object?> get props => [data];
}

class FetchBankAccount extends DeliveryEvent {}

class DeleteBankAccount extends DeliveryEvent {}

class UpdateDeliveryLocation extends DeliveryEvent {
  final double latitude;
  final double longitude;
  final double speed;
  final double bearing;

  const UpdateDeliveryLocation({
    required this.latitude,
    required this.longitude,
    this.speed = 0,
    this.bearing = 0,
  });

  @override
  List<Object?> get props => [latitude, longitude, speed, bearing];
}

class FetchEarnings extends DeliveryEvent {
  final int limit;
  final int offset;

  const FetchEarnings({this.limit = 20, this.offset = 0});

  @override
  List<Object?> get props => [limit, offset];
}

class FetchEarningSummary extends DeliveryEvent {}

class GoOnline extends DeliveryEvent {
  final String? deviceId;
  final String? appVersion;

  const GoOnline({this.deviceId, this.appVersion});

  @override
  List<Object?> get props => [deviceId, appVersion];
}

class GoOffline extends DeliveryEvent {}

class SendHeartbeat extends DeliveryEvent {}

class FetchAssignedOrders extends DeliveryEvent {}

class FetchOrderDetail extends DeliveryEvent {
  final String orderId;

  const FetchOrderDetail(this.orderId);

  @override
  List<Object?> get props => [orderId];
}

class VerifyOtp extends DeliveryEvent {
  final String orderId;
  final String otp;
  final String otpType;

  const VerifyOtp(this.orderId, this.otp, {this.otpType = 'delivery'});

  @override
  List<Object?> get props => [orderId, otp, otpType];
}

class ClaimDeliveryOrder extends DeliveryEvent {
  final String orderId;

  const ClaimDeliveryOrder(this.orderId);

  @override
  List<Object?> get props => [orderId];
}

class AcceptAssignment extends DeliveryEvent {
  final String orderId;

  const AcceptAssignment(this.orderId);

  @override
  List<Object?> get props => [orderId];
}

class RejectAssignment extends DeliveryEvent {
  final String orderId;

  const RejectAssignment(this.orderId);

  @override
  List<Object?> get props => [orderId];
}

class PickupOrder extends DeliveryEvent {
  final String orderId;

  const PickupOrder(this.orderId);

  @override
  List<Object?> get props => [orderId];
}

class OutForDelivery extends DeliveryEvent {
  final String orderId;

  const OutForDelivery(this.orderId);

  @override
  List<Object?> get props => [orderId];
}

class DeliverOrder extends DeliveryEvent {
  final String orderId;

  const DeliverOrder(this.orderId);

  @override
  List<Object?> get props => [orderId];
}
