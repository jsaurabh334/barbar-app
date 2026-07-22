import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/delivery_repository.dart';
import 'delivery_event.dart';
import 'delivery_state.dart';

class DeliveryBloc extends Bloc<DeliveryEvent, DeliveryState> {
  final DeliveryRepository _deliveryRepository;

  DeliveryBloc(this._deliveryRepository) : super(DeliveryInitial()) {
    on<LoadDeliveryProfile>(_onLoadProfile);
    on<RegisterDelivery>(_onRegister);
    on<SaveBankAccount>(_onSaveBankAccount);
    on<FetchBankAccount>(_onFetchBankAccount);
    on<DeleteBankAccount>(_onDeleteBankAccount);
    on<FetchEarnings>(_onFetchEarnings);
    on<FetchEarningSummary>(_onFetchEarningSummary);
    on<UpdateDeliveryLocation>(_onUpdateLocation);
    on<GoOnline>(_onGoOnline);
    on<GoOffline>(_onGoOffline);
    on<SendHeartbeat>(_onHeartbeat);
    on<FetchAssignedOrders>(_onFetchAssignedOrders);
    on<FetchOrderDetail>(_onFetchOrderDetail);
    on<VerifyOtp>(_onVerifyOtp);
    on<AcceptAssignment>(_onAcceptAssignment);
    on<ClaimDeliveryOrder>(_onClaimDeliveryOrder);
    on<RejectAssignment>(_onRejectAssignment);
    on<PickupOrder>(_onPickupOrder);
    on<OutForDelivery>(_onOutForDelivery);
    on<DeliverOrder>(_onDeliverOrder);
  }

  Future<void> _onLoadProfile(LoadDeliveryProfile event, Emitter<DeliveryState> emit) async {
    emit(DeliveryLoading());
    try {
      final profile = await _deliveryRepository.getProfile().timeout(const Duration(seconds: 5));
      emit(DeliveryProfileLoaded(profile));
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('404') || msg.contains('not found')) {
        emit(DeliveryNoProfile());
      } else if (msg.contains('timeout') || msg.contains('connection refused')) {
        emit(DeliveryFailure('Server not reachable. Ensure backend is running on localhost:8080'));
      } else {
        emit(DeliveryFailure(msg.replaceAll('exception: ', '')));
      }
    }
  }

  Future<void> _onRegister(RegisterDelivery event, Emitter<DeliveryState> emit) async {
    emit(DeliveryLoading());
    try {
      await _deliveryRepository.register(event.data);
      final profile = await _deliveryRepository.getProfile();
      emit(DeliverySuccess('Registration submitted for approval'));
      emit(DeliveryProfileLoaded(profile));
    } catch (e) {
      emit(DeliveryFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onSaveBankAccount(SaveBankAccount event, Emitter<DeliveryState> emit) async {
    try {
      await _deliveryRepository.upsertBankAccount(event.data);
      emit(DeliverySuccess('Bank account saved'));
    } catch (e) {
      emit(DeliveryFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onFetchBankAccount(FetchBankAccount event, Emitter<DeliveryState> emit) async {
    emit(DeliveryLoading());
    try {
      final account = await _deliveryRepository.getBankAccount();
      emit(DeliveryBankAccountLoaded(account));
    } catch (e) {
      emit(DeliveryFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onDeleteBankAccount(DeleteBankAccount event, Emitter<DeliveryState> emit) async {
    try {
      await _deliveryRepository.deleteBankAccount();
      emit(DeliverySuccess('Bank account deleted'));
    } catch (e) {
      emit(DeliveryFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onFetchEarnings(FetchEarnings event, Emitter<DeliveryState> emit) async {
    emit(DeliveryLoading());
    try {
      final earnings = await _deliveryRepository.getEarnings(limit: event.limit, offset: event.offset);
      emit(DeliveryEarningsLoaded(earnings));
    } catch (e) {
      emit(DeliveryFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onFetchEarningSummary(FetchEarningSummary event, Emitter<DeliveryState> emit) async {
    emit(DeliveryLoading());
    try {
      final summary = await _deliveryRepository.getEarningSummary();
      final earnings = await _deliveryRepository.getEarnings(limit: 50);
      emit(DeliveryEarningsLoaded(earnings, summary: summary));
    } catch (e) {
      emit(DeliveryFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onUpdateLocation(UpdateDeliveryLocation event, Emitter<DeliveryState> emit) async {
    try {
      await _deliveryRepository.sendLocation(
        latitude: event.latitude,
        longitude: event.longitude,
        speed: event.speed,
        bearing: event.bearing,
        timestamp: DateTime.now().toUtc().toIso8601String(),
      );
    } catch (_) {}
  }

  Future<void> _onGoOnline(GoOnline event, Emitter<DeliveryState> emit) async {
    emit(DeliveryLoading());
    try {
      final result = await _deliveryRepository.goOnline(
        deviceId: event.deviceId,
        appVersion: event.appVersion,
      );
      final status = result['status'] as String? ?? 'online';
      emit(DeliveryPresenceUpdated(status));
    } catch (e) {
      emit(DeliveryFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onGoOffline(GoOffline event, Emitter<DeliveryState> emit) async {
    emit(DeliveryLoading());
    try {
      await _deliveryRepository.goOffline();
      emit(DeliveryPresenceUpdated('offline'));
    } catch (e) {
      emit(DeliveryFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onHeartbeat(SendHeartbeat event, Emitter<DeliveryState> emit) async {
    try {
      await _deliveryRepository.heartbeat();
    } catch (_) {}
  }

  Future<void> _onFetchAssignedOrders(FetchAssignedOrders event, Emitter<DeliveryState> emit) async {
    emit(DeliveryLoading());
    try {
      final orders = await _deliveryRepository.getAssignedOrders();
      emit(DeliveryOrdersLoaded(orders));
    } catch (e) {
      emit(DeliveryFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onFetchOrderDetail(FetchOrderDetail event, Emitter<DeliveryState> emit) async {
    emit(DeliveryLoading());
    try {
      final order = await _deliveryRepository.getOrderById(event.orderId);
      emit(DeliveryOrderDetailLoaded(order));
    } catch (e) {
      emit(DeliveryFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onVerifyOtp(VerifyOtp event, Emitter<DeliveryState> emit) async {
    try {
      await _deliveryRepository.verifyOtp(event.orderId, event.otp, otpType: event.otpType);
      emit(DeliverySuccess('OTP verified'));
    } catch (e) {
      emit(DeliveryFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onAcceptAssignment(AcceptAssignment event, Emitter<DeliveryState> emit) async {
    try {
      await _deliveryRepository.acceptAssignment(event.orderId);
      emit(DeliverySuccess('Assignment accepted'));
      final orders = await _deliveryRepository.getAssignedOrders();
      emit(DeliveryOrdersLoaded(orders));
    } catch (e) {
      emit(DeliveryFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onClaimDeliveryOrder(ClaimDeliveryOrder event, Emitter<DeliveryState> emit) async {
    try {
      emit(DeliveryLoading());
      await _deliveryRepository.claimOrder(event.orderId);
      emit(DeliverySuccess('Order claimed successfully!'));
      final order = await _deliveryRepository.getOrderById(event.orderId);
      emit(DeliveryOrderDetailLoaded(order));
    } catch (e) {
      emit(DeliveryFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onRejectAssignment(RejectAssignment event, Emitter<DeliveryState> emit) async {
    try {
      await _deliveryRepository.rejectAssignment(event.orderId);
      emit(DeliverySuccess('Assignment rejected'));
      final orders = await _deliveryRepository.getAssignedOrders();
      emit(DeliveryOrdersLoaded(orders));
    } catch (e) {
      emit(DeliveryFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onPickupOrder(PickupOrder event, Emitter<DeliveryState> emit) async {
    try {
      final order = await _deliveryRepository.pickupOrder(event.orderId);
      emit(DeliveryOrderDetailLoaded(order));
      final orders = await _deliveryRepository.getAssignedOrders();
      emit(DeliveryOrdersLoaded(orders));
    } catch (e) {
      emit(DeliveryFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onOutForDelivery(OutForDelivery event, Emitter<DeliveryState> emit) async {
    try {
      final order = await _deliveryRepository.outForDelivery(event.orderId);
      emit(DeliveryOrderDetailLoaded(order));
      final orders = await _deliveryRepository.getAssignedOrders();
      emit(DeliveryOrdersLoaded(orders));
    } catch (e) {
      emit(DeliveryFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onDeliverOrder(DeliverOrder event, Emitter<DeliveryState> emit) async {
    try {
      final order = await _deliveryRepository.deliverOrder(event.orderId);
      emit(DeliveryOrderDetailLoaded(order));
      final orders = await _deliveryRepository.getAssignedOrders();
      emit(DeliveryOrdersLoaded(orders));
    } catch (e) {
      emit(DeliveryFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
